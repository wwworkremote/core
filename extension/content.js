// WWWorkRemote Content Script — Rich Context Extraction
//
// Two trigger modes:
//   enrich  — URL contains ?wwr_id=NNN, appended by the Rails app when the
//             user clicks SOURCE_ORIGIN_VERIFY_&_ENRICH on a job posting show
//             page. Enriches that existing JobPosting.
//   capture — free browsing, no wwr_id. Auto-detects a supported job board's
//             detail page (confirmed via provider.readySelector) and creates
//             a Lead, later promoted to a JobPosting once the user reviews
//             and submits the panel.
//
// Extraction priority chain (highest confidence first):
//   1. JSON-LD  Schema.org JobPosting — structured, authoritative, zero selector drift
//   2. Provider CSS selectors         — board-specific, maintained per provider
//   3. Open Graph / Meta tags         — title, description, canonical URL
//   4. Generic heuristics             — <main>, <article>, largest content block
//   5. Raw DOM                        — always captured; backend CSS extractor last resort

(function () {
  'use strict';

  // Manual "Scan This Page" (popup.js) can inject this file more than once
  // into the same tab -- avoid stacking duplicate overlays/listeners.
  if (document.getElementById('wwr-enrichment-overlay')) return;

  const urlParams = new URLSearchParams(window.location.search);
  const wwrId = urlParams.get('wwr_id');

  // Set by popup.js's "Scan This Page" button immediately before injecting
  // this file, via a separate executeScript call -- allows generic capture
  // on a non-curated host for this one on-demand injection only. Consumed
  // (cleared) immediately so it can't linger across any future re-injection.
  const manualScan = !!window.__wwrManualScan;
  window.__wwrManualScan = false;

  // ─── Structured console logger ─────────────────────────────────────────────
  // All logs prefixed [WWWR HH:MM:SS.mmm] — filter DevTools console by [WWWR].

  const ts     = () => new Date().toISOString().slice(11, 23);

  // Mirrors every LOG* call into the side panel's diagnostics log (visible
  // without opening DevTools) -- fire-and-forget, and swallowed if the
  // extension context has gone away (e.g. mid-navigation).
  function reportDiag(level, args, detail) {
    try {
      const text = args.map(a => (a instanceof Error ? a.message : String(a))).join(' ');
      const msg = { type: 'DIAG_LOG', level, text, ts: Date.now() };
      // detail carries structured data (raw JSON-LD, extraction metadata) so
      // it's inspectable in the panel's diagnostics log without opening
      // DevTools -- capped to keep chrome.storage.session well under quota.
      if (detail !== undefined) msg.detail = JSON.stringify(detail, null, 2).slice(0, 4000);
      chrome.runtime.sendMessage(msg);
    } catch (_) { /* ignore */ }
  }

  const LOG      = (...a) => { console.log(   `%c[WWWR ${ts()}]`,   'color:#9580ff;font-weight:bold', ...a); reportDiag('info', a); };
  const LOG_OK   = (...a) => { console.log(   `%c[WWWR ${ts()}] ✓`, 'color:#8aff80;font-weight:bold', ...a); reportDiag('ok', a); };
  const LOG_WARN = (...a) => { console.warn(  `%c[WWWR ${ts()}] ⚠`, 'color:#ffff80;font-weight:bold', ...a); reportDiag('warn', a); };
  const LOG_ERR  = (...a) => { console.error( `%c[WWWR ${ts()}] ✗`, 'color:#ff9580;font-weight:bold', ...a); reportDiag('err', a); };
  const LOG_GRP  = (label, fn) => {
    console.groupCollapsed(`%c[WWWR] ${label}`, 'color:#9590c5;font-weight:bold');
    fn();
    console.groupEnd();
  };

  // ─── Provider definitions ──────────────────────────────────────────────────
  //
  // readySelector  CSS selector whose presence signals the SPA has rendered.
  //                The extension waits for this before capturing (fixes LinkedIn/Indeed timing).
  // readyTimeout   Max ms to wait before proceeding anyway.
  // extract(doc)   Provider-specific CSS extraction. Runs after JSON-LD attempt.

  const PROVIDERS = {

    // ── Job boards ──────────────────────────────────────────────────────────

    // Verified live against a real posting on the split-view search
    // results layout (the far more common entry point than a standalone
    // job page). LinkedIn has since renamed its top-card classes to a
    // `job-details-jobs-unified-top-card__*` scheme -- company/location/
    // pills all silently returned null under the old
    // `.jobs-unified-top-card__*`/`.topcard__*` names, leaving only
    // title+description (title's own `h1` bare fallback happened to still
    // work). Pills no longer live in a `__job-insight` wrapper at all --
    // they're bare `<strong>` tags inside the top-card container, mixed in
    // with unrelated strongs ("Actively reviewing applicants"), so still
    // classified by content (classifyInsightPills), not assumed shape.
    linkedin: {
      label: 'LinkedIn',
      match: h => h.includes('linkedin.com'),
      readySelector: '.show-more-less-html__markup, .jobs-description__content, .description__text',
      readyTimeout: 8000,
      extract(doc) {
        const pills = pickAllText(
          doc,
          '.job-details-jobs-unified-top-card__container--two-pane strong, ' +
          '.jobs-unified-top-card__job-insight span, .job-details-jobs-unified-top-card__job-insight span'
        );
        return {
          title:            pickText(doc, 'h1.top-card-layout__title, h1.jobs-unified-top-card__job-title, h1'),
          company:          pickText(doc, '.job-details-jobs-unified-top-card__company-name, .topcard__org-name-link, .jobs-unified-top-card__company-name a, .top-card-layout__first-subline a'),
          location:         pickText(doc, '.job-details-jobs-unified-top-card__tertiary-description-container .tvm__text, .topcard__flavor--bullet, .jobs-unified-top-card__bullet'),
          posted_at:        pickText(doc, '.posted-time-ago__text, .jobs-unified-top-card__posted-date'),
          ...classifyInsightPills(pills),
          description_html: pickHtml(doc, '.show-more-less-html__markup, .description__text--rich, .jobs-description__content'),
          description_text: pickInnerText(doc, '.description__text, .jobs-description__content'),
        };
      },
    },

    // Verified live against 3 real postings, both page shapes Indeed
    // serves (the full /viewjob?jk= page, and the split-view detail pane
    // shown inline on /jobs?q=...&vjk= search results -- the far more
    // common entry point when clicking a card without opening a new tab).
    // Three real bugs found: (1) the old `h1.jobsearch-JobInfoHeader-title`
    // compound selector required the title to BE an h1 -- true on the full
    // page, but the split-view pane renders the identically-classed title
    // as an h2, so the bare `h1` fallback silently grabbed the search
    // page's own h1 ("software engineer jobs") instead -- same root-cause
    // class as TASK-47 (a different file: the server-side email/API
    // extractor). Fixed by matching the class alone, tag-agnostic. (2) The
    // split-view title also has a UI-only " - job post" suffix nested in a
    // hashed-class child span -- stripped like Greenhouse's logo-alt
    // cleanup. (3) `.jobsearch-JobInfoHeader-subtitle` (location) and
    // `.attribute_snippet` (salary) no longer exist anywhere in the
    // current markup -- salary/job-type now share one `#salaryInfoAndJobType`
    // container as two hashed-class sibling spans with no way to tell them
    // apart by selector, so classified by content (SALARY_PILL) like
    // LinkedIn's insight pills instead of by position.
    indeed: {
      label: 'Indeed',
      match: h => h.includes('indeed.com'),
      readySelector: '.jobsearch-JobInfoHeader-title, #jobDescriptionText, .jobsearch-JobComponent-description',
      readyTimeout: 6000,
      extract(doc) {
        const title = pickText(doc, '.jobsearch-JobInfoHeader-title, h1')?.replace(/\s*-\s*job post\s*$/i, '');
        const salaryText = pickAllText(doc, '#salaryInfoAndJobType span').find(t => SALARY_PILL.test(t));
        return {
          title,
          company:          pickText(doc, '[data-company-name="true"], .jobsearch-InlineCompanyRating div'),
          location:         pickText(doc, '[data-testid="job-location"], .jobsearch-JobInfoHeader-subtitle div:last-child'),
          ...(salaryText ? parseSalaryPill(salaryText) : {}),
          description_html: pickHtml(doc, '#jobDescriptionText, .jobsearch-JobComponent-description'),
          description_text: pickInnerText(doc, '#jobDescriptionText, .jobsearch-JobComponent-description'),
        };
      },
    },

    // Verified live against two real postings (different companies/templates
    // on the same www.adzuna.com/details/* page shape). The old guessed
    // selectors were wrong on every field except location/salary, and those
    // two only worked by accident: Adzuna's real classes are .ui-company,
    // .ui-location, .ui-salary, and .adp-body (description) -- the old
    // `[class*="location"]`/`[class*="salary"]` wildcards happen to match
    // "ui-location"/"ui-salary" as a substring, but `.company`/
    // `[class*="company-name"]` never matches "ui-company", and
    // `.job-description`/`[class*="JobDescription"]` never matches
    // "adp-body" at all -- both silently returned null. JSON-LD (checked
    // first in the extraction chain) happened to cover company/description
    // as a fallback, which is why this went unnoticed.
    adzuna: {
      label: 'Adzuna',
      match: h => h.includes('adzuna.com'),
      readySelector: '.adp-body, .ui-company',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1'),
          company:          pickText(doc, '.ui-company'),
          location:         pickText(doc, '.ui-location'),
          salary:           pickText(doc, '.ui-salary'),
          description_html: pickHtml(doc, '.adp-body'),
          description_text: pickInnerText(doc, '.adp-body'),
        };
      },
    },

    // Verified live against two real postings after WWR's 2026 redesign --
    // the old .listing-header--company/.region/.listing-header--salary
    // classes are gone entirely (silently returned null, not an error).
    // Neither posting exposed company/location/salary as discrete DOM
    // nodes at all; company only appears in the "Title at Company"
    // <title>/og:title pattern. The whole board is remote-only by
    // platform definition, so `remote`/`location` are facts about WWR
    // itself, not something to parse per-posting.
    weworkremotely: {
      label: 'WeWorkRemotely',
      match: h => h.includes('weworkremotely.com'),
      readySelector: '.lis-container__job__content__description, .lis-container__header__hero__company-info__title',
      readyTimeout: 5000,
      extract(doc) {
        const descSel = '.lis-container__job__content__description';
        return {
          title:            pickText(doc, '.lis-container__header__hero__company-info__title, h1'),
          company:          companyFromTitleSuffix(doc),
          location:         'Remote',
          remote:           'Remote',
          description_html: pickHtml(doc, descSel),
          description_text: pickInnerText(doc, descSel),
        };
      },
    },

    remoteok: {
      label: 'RemoteOK',
      match: h => h.includes('remoteok.com'),
      readySelector: '[itemprop="description"], .description',
      readyTimeout: 5000,
      extract(doc) {
        const tags = Array.from(doc.querySelectorAll('.tags .tag, .tag'))
          .map(el => el.textContent.trim()).filter(Boolean);
        return {
          title:            pickText(doc, 'h1, .job_title'),
          company:          pickText(doc, 'h3, .company'),
          location:         pickText(doc, '.location, .region'),
          salary:           pickText(doc, '.salary'),
          tags:             tags.length ? tags : null,
          description_html: pickHtml(doc, '[itemprop="description"], .description'),
          description_text: pickInnerText(doc, '[itemprop="description"], .description'),
        };
      },
    },

    // ── ATS platforms ───────────────────────────────────────────────────────
    // Many remote job listings link directly to company career pages hosted
    // on these platforms. JSON-LD is attempted first on all of them.

    // Verified live against a real job-boards.greenhouse.io posting (2026
    // template): no JSON-LD, .company-name/.employer-name never match --
    // company only exists as the logo's alt="X Logo" (title-suffix parse
    // as fallback for boards without a logo). .job__description and
    // .employment-type are unchanged from the old template and still work.
    // Salary, when a company discloses one, lives in .job__pay-ranges as
    // prose ("Annual Salary: $405,000 - $485,000 USD"), not a pill --
    // parseSalaryPill's regex still finds the number pair inside it.
    greenhouse: {
      label: 'Greenhouse',
      match: h => h.includes('greenhouse.io'),
      readySelector: '.job__description, #content, .section-wrapper',
      readyTimeout: 5000,
      extract(doc) {
        const logoAlt = pickAttr(doc, '.job__header img[alt], img[alt*="logo" i]', 'alt');
        const company = logoAlt ? logoAlt.replace(/\s*logo\s*$/i, '').trim() : companyFromTitleSuffix(doc);
        const payRangeText = pickText(doc, '.job__pay-ranges');
        return {
          title:            pickText(doc, 'h1.app-title, h1'),
          company,
          location:         pickText(doc, '.job__location, .location, .job-location, .office'),
          employment_type:  pickText(doc, '.employment-type'),
          ...(payRangeText ? parseSalaryPill(payRangeText) : {}),
          description_html: pickHtml(doc, '.job__description, #content, .section-wrapper'),
          description_text: pickInnerText(doc, '.job__description, #content, .section-wrapper'),
        };
      },
    },

    lever: {
      label: 'Lever',
      match: h => h.includes('lever.co'),
      readySelector: '.posting-description, .content',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h2.posting-headline, .posting-headline h2, h2'),
          // Lever embeds "Company is hiring a Title" — extract company separately
          company:          pickText(doc, '.main-header-text h1, .posting-company'),
          location:         pickText(doc, '.sort-by-time.posting-category, .location, .workplaceTypes'),
          employment_type:  pickText(doc, '.workplaceTypes, .commitment'),
          description_html: pickHtml(doc, '.posting-description, .content'),
          description_text: pickInnerText(doc, '.posting-description, .content'),
        };
      },
    },

    // Verified live against two real tenants (Intel, Barclays). Two real
    // bugs found: (1) .css-129m7dg (a hashed CSS-module class, inherently
    // unstable across Workday's own deploys) currently resolves to the
    // *location* value, not company -- confirmed by inspecting the DOM,
    // not assumed; (2) [data-automation-id="locations"]/["time"] wrap a
    // <dt>/<dd> pair (label + value) and the old selectors read the whole
    // container's textContent, concatenating the invisible label onto the
    // value ("locationsUS, Oregon, Hillsboro"). Scoping to the `dd` fixes
    // both fields. Company has no reliable per-tenant DOM node at all
    // (header text and logo alt both vary/are empty across tenants) --
    // see companyFromWorkdayHostname().
    workday: {
      label: 'Workday',
      // Matches *.workday.com and *.myworkdayjobs.com
      match: h => h.includes('workday.com') || h.includes('myworkdayjobs.com'),
      // Workday is a heavy React SPA — generous timeout
      readySelector: '[data-automation-id="jobPostingDescription"], [data-automation-id="job-posting-details"]',
      readyTimeout: 10000,
      extract(doc) {
        return {
          title:            pickText(doc, '[data-automation-id="jobPostingHeader"], h1'),
          company:          companyFromWorkdayHostname(),
          location:         pickText(doc, '[data-automation-id="locations"] dd, [data-automation-id="locations"]'),
          employment_type:  pickText(doc, '[data-automation-id="time"] dd, [data-automation-id="time"]'),
          description_html: pickHtml(doc, '[data-automation-id="jobPostingDescription"], [data-automation-id="job-posting-details"]'),
          description_text: pickInnerText(doc, '[data-automation-id="jobPostingDescription"], [data-automation-id="job-posting-details"]'),
        };
      },
    },

    // Verified live against a real Ashby posting. JSON-LD is present and
    // reliable here (title/company/employment_type/structured salary all
    // correct) EXCEPT jobLocation, which the posting left empty -- location
    // is the one field genuinely worth pulling from CSS. All the old
    // [class*="X"] selectors were guessing at hashed CSS-Modules class
    // names (e.g. "_section_f7cvd_36") that change every Ashby deploy, so
    // location/employment_type now key off the heading text within the
    // stable, plainly-named .ashby-job-posting-left-pane container instead
    // -- see pickLabeledValue(). description_html/text left as-is: broken
    // the same way, but harmless since JSON-LD's description always wins.
    ashby: {
      label: 'Ashby',
      match: h => h.includes('ashby.com') || h.includes('ashbyhq.com'),
      readySelector: '[class*="JobPosting"], [class*="jobPosting"], [class*="Description"]',
      readyTimeout: 6000,
      extract(doc) {
        const pane = '.ashby-job-posting-left-pane';
        return {
          title:            pickText(doc, 'h1'),
          company:          pickText(doc, '[class*="CompanyName"], [class*="companyName"]'),
          location:         pickLabeledValue(doc, pane, /^location/i) || pickText(doc, '[class*="Location"], [class*="location"]'),
          employment_type:  pickLabeledValue(doc, pane, /^employment type/i) || pickText(doc, '[class*="EmploymentType"], [class*="employmentType"]'),
          description_html: pickHtml(doc, '[class*="JobPosting-description"], [class*="jobPostingDescription"], [class*="Description"]'),
          description_text: pickInnerText(doc, '[class*="JobPosting-description"], [class*="jobPostingDescription"], [class*="Description"]'),
        };
      },
    },

    // Verified live against two real ServiceNow-hosted SmartRecruiters
    // postings (one had expired -- useful negative case, confirmed its
    // empty description was real, not a selector bug). No <script
    // type="application/ld+json">, but a real schema.org Microdata tree
    // (itemprop attributes) IS present in the live DOM -- see
    // microdataJobPosting(). The .summary-detail selectors below turned out
    // to target markup that only exists inside a
    // <script type="text/template"> print-summary widget, never real DOM
    // (confirmed live on an NBCUniversal posting: 0 matches, location and
    // employment_type always came back null), and salary was never even
    // attempted despite being disclosed via itemprop="baseSalary" on U.S.
    // postings. Microdata now does the real work; the old selectors stay on
    // as a fallback for tenants whose page doesn't carry this Microdata
    // shape. Description spans multiple .wysiwyg.spl-wysiwyg sections
    // (About/Requirements/etc), so it's pulled from their shared
    // .job-sections wrapper, not a single node -- unaffected by any of the
    // above, left as-is.
    smartrecruiters: {
      label: 'SmartRecruiters',
      match: h => h.includes('smartrecruiters.com'),
      readySelector: '.job-sections, .job-description, .details-content, [itemprop="description"]',
      readyTimeout: 5000,
      extract(doc) {
        const micro = microdataJobPosting(doc);
        return {
          title:             micro?.title            || pickText(doc, 'h1[itemprop="title"], h1.job-title, h1'),
          company:           micro?.company           || companyFromSmartRecruitersPath(),
          company_logo_url:  micro?.company_logo_url,
          location:          micro?.location          || pickText(doc, 'span.summary-detail, .job-location'),
          employment_type:   micro?.employment_type   || pickText(doc, 'li.summary-detail, .job-type'),
          salary_min:        micro?.salary_min,
          salary_max:        micro?.salary_max,
          salary_currency:   micro?.salary_currency,
          salary_unit:       micro?.salary_unit,
          industry:          micro?.industry,
          description_html: pickHtml(doc, '.job-sections, .job-description, .details-content, [itemprop="description"]'),
          description_text: pickInnerText(doc, '.job-sections, .job-description, .details-content, [itemprop="description"]'),
        };
      },
    },

    // Verified live against real Dice postings (both page variants):
    //  - /job-detail/<id>  -- has a reliable schema.org JobPosting JSON-LD
    //    block (title/company/location/description/employmentType all
    //    present), so tier 1 covers this case and the CSS below barely
    //    matters here -- JSON-LD always wins the merge when present.
    //  - /jobs?...&selectedJobId=<id>  -- the search split-view. NO JSON-LD
    //    at all here; only the title (bare `h1`) and company are reliably
    //    gettable via simple selectors. The description selector below is
    //    a deep, position-dependent chain (Dice gives it no id/data-testid)
    //    that only matches correctly on THIS split-view layout -- on the
    //    standalone page it grabs the wrong (short) node, but that's
    //    harmless since JSON-LD overrides it there anyway. If Dice reshuffles
    //    this layout, re-teach via the picker rather than re-guessing here.
    // Salary/employment-type/remote come from Dice's own .SeuiInfoBadge
    // pills (a real design-system class, not a hashed utility) via the
    // same classifyInsightPills() used for LinkedIn -- same "insight pill"
    // pattern, different site.
    dice: {
      label: 'Dice',
      match: h => h.includes('dice.com'),
      readySelector: '[data-testid="job-detail-header-card"]',
      readyTimeout: 6000,
      extract(doc) {
        const descSel = '[class*="@container/job-detail"] > div:last-child > div:first-child > div:first-child';
        const pills = pickAllText(doc, '[data-testid="job-detail-header-card"] .SeuiInfoBadge');
        return {
          title:            pickText(doc, '[data-testid="job-detail-header-card"] h1, h1'),
          company:          pickText(doc, '[data-testid="job-detail-header-card"] a[href*="/company-profile/"]'),
          location:         pickText(doc, '[data-testid="job-detail-header-card"] .text-font-light > span:first-child'),
          ...classifyInsightPills(pills),
          description_html: pickHtml(doc, descSel),
          description_text: pickInnerText(doc, descSel),
        };
      },
    },

    // Verified live against two real postings (different companies).
    // The old selectors were all camelCase-guess CSS-module class names
    // (jobDescription, StartupName, ...) -- Wellfound's actual markup is
    // Tailwind utility classes with no such names anywhere, so every field
    // but title silently returned null. company/location instead use the
    // only stable hooks on the page: the /company/<slug> and /location/
    // <slug> href structure (the company link needs :not(.content-center)
    // since the logo image is wrapped in an identical-shaped, but text-
    // empty, sibling anchor). salary/employment_type have no href or
    // data-* hook at all -- positional (h1's sibling <ul>'s 1st/last <li>)
    // is the only option; confirmed stable (empty <li> preserved, not
    // omitted, on a listing with no disclosed salary) rather than the list
    // reshuffling. description has no data-* hook either; targeted via its
    // two Tailwind utility classes together (.rounded-xl.border-gray-400),
    // which only ever match the one description card, not the header card
    // (.border-neutral-200).
    wellfound: {
      label: 'Wellfound',
      match: h => h.includes('wellfound.com'),
      readySelector: 'h1, .rounded-xl.border-gray-400',
      readyTimeout: 6000,
      extract(doc) {
        const descSel = '.rounded-xl.border-gray-400';
        return {
          title:            pickText(doc, 'h1'),
          company:          pickText(doc, '[data-testid="startup-header"] a[href^="/company/"]:not(.content-center)'),
          location:         pickText(doc, 'h1 + ul a[href^="/location/"], h1 + ul li:nth-child(2)'),
          salary:           pickText(doc, 'h1 + ul li:first-child'),
          description_html: pickHtml(doc, descSel),
          description_text: pickInnerText(doc, descSel),
        };
      },
    },

  };

  // ─── Null-safe object merge ────────────────────────────────────────────────
  // Like Object.assign but skips null/undefined values so a null field in a
  // higher-priority source never clobbers a real value from a lower source.

  function mergeNonNull(target, ...sources) {
    for (const src of sources) {
      if (!src) continue;
      for (const [k, v] of Object.entries(src)) {
        // A blank string is treated the same as null/undefined: a source
        // that found nothing shouldn't clobber a real value a lower-priority
        // source already filled in (e.g. Workday's JSON-LD reliably reports
        // hiringOrganization.name: "", which would otherwise blank out the
        // CSS tier's companyFromWorkdayHostname() fallback).
        if (v !== null && v !== undefined && v !== '') target[k] = v;
        else if (!(k in target))                       target[k] = v; // keep first null/blank as placeholder
      }
    }
    return target;
  }

  // ─── Element picker: candidate selector computation ───────────────────────
  // Not the final answer -- sent to the backend as a starting point for
  // JobBoards::SelectorLearnerAgent, which prefers a more stable hook
  // (id/data-*/itemprop) when one exists in the clicked element's context.
  function computeSelector(el) {
    if (el.id) return `#${CSS.escape(el.id)}`;
    const parts = [];
    let node = el;
    while (node && node.nodeType === 1 && parts.length < 6) {
      let part = node.tagName.toLowerCase();
      if (node.classList.length) {
        part += '.' + [...node.classList].slice(0, 3).map(c => CSS.escape(c)).join('.');
      }
      const siblings = node.parentElement
        ? [...node.parentElement.children].filter(s => s.tagName === node.tagName)
        : [];
      if (siblings.length > 1) part += `:nth-of-type(${siblings.indexOf(node) + 1})`;
      parts.unshift(part);
      if (node.id) { parts[0] = `#${CSS.escape(node.id)}`; break; }
      node = node.parentElement;
    }
    return parts.join(' > ');
  }

  // Some boards (confirmed live on RemoteOK) embed JSON-LD for their whole
  // job feed on every single posting page, not just the one being viewed --
  // none of it carries a url/identifier field to key off, so the only
  // available signal is whether the candidate's title actually shows up
  // anywhere on this specific page. Without this, jsonLd() would happily
  // return a stranger's job as tier-1 "authoritative" data for whatever the
  // user is actually looking at.
  const JSON_LD_TITLE_PREFIX_LEN = 20;

  function jsonLdMatchesCurrentPage(doc, item) {
    if (!item.title) return true; // nothing to check against -- don't block on missing data
    const pageText = (doc.querySelector('h1')?.textContent || doc.title || '').toLowerCase();
    if (!pageText) return true;
    const prefix = item.title.toLowerCase().slice(0, JSON_LD_TITLE_PREFIX_LEN);
    return pageText.includes(prefix);
  }

  // ─── DOM helpers ───────────────────────────────────────────────────────────

  function pickText(doc, selectors) {
    for (const sel of selectors.split(',').map(s => s.trim())) {
      const t = doc.querySelector(sel)?.textContent?.trim();
      if (t) return t;
    }
    return null;
  }

  // Like pickText, but reads an attribute instead of textContent -- for
  // company logos, where the name only exists as alt="Acme Logo".
  function pickAttr(doc, selectors, attr) {
    for (const sel of selectors.split(',').map(s => s.trim())) {
      const v = doc.querySelector(sel)?.getAttribute(attr);
      if (v) return v.trim();
    }
    return null;
  }

  // Several ATS boards (confirmed on WeWorkRemotely and Greenhouse) render
  // <title>/og:title as "Job Title at Company" with no separate company
  // DOM node at all -- this is the shared fallback for that pattern.
  function companyFromTitleSuffix(doc) {
    const t = pickText(doc, 'title') || '';
    return t.includes(' at ') ? t.split(' at ').pop().trim() : null;
  }

  // Workday-hosted career sites (verified on Intel and Barclays) expose no
  // consistent DOM node for the company name -- header text, logo alt, and
  // page <title> all vary or are empty per tenant. The one thing that's
  // always there: every tenant's board is hosted at
  // {company}.wdN.myworkdayjobs.com, so the hostname itself is the most
  // reliable signal available.
  function companyFromWorkdayHostname() {
    const sub = window.location.hostname.split('.')[0];
    return sub ? sub.replace(/[-_]/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) : null;
  }

  // SmartRecruiters URLs are jobs.smartrecruiters.com/{Company}/{id}-{slug}
  // -- the company segment keeps its real casing (e.g. "ServiceNow"), so
  // unlike the Workday hostname this needs no title-casing pass.
  function companyFromSmartRecruitersPath() {
    return window.location.pathname.split('/')[1] || null;
  }

  // Reads schema.org Microdata (itemprop attributes), the sibling format to
  // JSON-LD that Extractor.jsonLd() doesn't parse. Confirmed live on a real
  // SmartRecruiters posting: no <script type="application/ld+json"> block,
  // but a full itemscope="JobPosting" tree with baseSalary -- data the old
  // per-provider CSS selectors (.summary-detail) never reached because that
  // markup turned out to live inside a <script type="text/template"> print
  // widget, never real DOM.
  function microdataVal(scope, prop) {
    if (!scope) return null;
    const el = scope.querySelector(`[itemprop="${prop}"]`);
    if (!el) return null;
    const v = (el.getAttribute('content') || el.textContent || '').trim();
    return v || null;
  }

  function microdataJobPosting(doc) {
    const root = doc.querySelector('[itemscope][itemtype*="JobPosting"]');
    if (!root) return null;

    const org    = root.querySelector('[itemprop="hiringOrganization"]');
    const loc    = root.querySelector('[itemprop="jobLocation"]');
    const salary = root.querySelector('[itemprop="baseSalary"]');
    const salaryValue = salary && salary.querySelector('[itemprop="value"]');

    const location = [
      microdataVal(loc, 'addressLocality'),
      microdataVal(loc, 'addressRegion'),
      microdataVal(loc, 'addressCountry'),
    ].filter(Boolean).join(', ') || null;

    return {
      title:             microdataVal(root, 'title'),
      company:           microdataVal(org, 'name'),
      company_logo_url:  microdataVal(org, 'logo'),
      location:          location,
      employment_type:   microdataVal(root, 'employmentType'),
      salary_currency:   microdataVal(salary, 'currency'),
      // minValue/maxValue come from a content="110000" attribute -- always a
      // string, unlike the JSON-LD tier's already-numeric baseSalary.value.
      salary_min:        salaryValue ? Number(microdataVal(salaryValue, 'minValue')) || null : null,
      salary_max:        salaryValue ? Number(microdataVal(salaryValue, 'maxValue')) || null : null,
      salary_unit:       microdataVal(salaryValue, 'unitText'),
      industry:          microdataVal(root, 'industry'),
      posted_at:         microdataVal(root, 'datePosted'),
      valid_through:     microdataVal(root, 'validThrough'),
    };
  }

  // Many ATS pages (confirmed on Ashby) render details as a heading/value
  // pair ("Location" / "San Francisco") wrapped in CSS-Modules classes that
  // change every deploy (e.g. "_section_f7cvd_36") -- unusable as selectors.
  // Scope to a stable, plainly-named container instead and match on the
  // heading text itself, which is far less likely to change than a build
  // hash.
  function pickLabeledValue(doc, containerSelector, labelPattern) {
    const container = doc.querySelector(containerSelector);
    if (!container) return null;
    const section = Array.from(container.querySelectorAll('div')).find(d =>
      d.children.length === 2 && labelPattern.test(d.children[0]?.textContent?.trim() || '')
    );
    return section?.children[1]?.textContent?.trim() || null;
  }

  // Like pickText, but returns every match's trimmed text (deduped) instead
  // of just the first -- for cases like LinkedIn's salary/workplace-type/
  // employment-type "insight pills", which are sibling elements matched by
  // the same selector, not a single value.
  function pickAllText(doc, selectors) {
    const seen = new Set();
    for (const sel of selectors.split(',').map(s => s.trim())) {
      for (const el of doc.querySelectorAll(sel)) {
        const t = el.textContent?.trim();
        if (t) seen.add(t);
      }
    }
    return [...seen];
  }

  // Classifies LinkedIn-style "insight pill" text (e.g. "$150K/yr - $240K/yr",
  // "Remote", "Full-time") into the field keys the panel actually reads.
  // Unrecognized pills are ignored rather than guessed at.
  const SALARY_PILL = /\$[\d,.]+\s*K?\s*(?:\/\s*\w+)?\s*-\s*\$?[\d,.]+\s*K?\s*(?:\/\s*(\w+))?/i;
  const EMPLOYMENT_PILL = /full[- ]?time|part[- ]?time|contract|freelance|temporary|temp\b|intern(ship)?|volunteer/i;
  const REMOTE_PILL = /remote|hybrid|on-?site/i;
  const SALARY_UNIT_MAP = { yr: 'YEAR', year: 'YEAR', hr: 'HOUR', hour: 'HOUR', mo: 'MONTH', month: 'MONTH' };

  function parseSalaryPill(text) {
    // Unit suffix varies by board: LinkedIn writes "/yr", Dice writes
    // "per year" -- accept either so the shared classifier works for both.
    const m = text.match(/\$?([\d,.]+)\s*(K)?\s*(?:(?:\/|per)\s*(\w+))?\s*-\s*\$?([\d,.]+)\s*(K)?\s*(?:(?:\/|per)\s*(\w+))?/i);
    if (!m) return { salary: text };
    const toNumber = (num, k) => parseFloat(num.replace(/,/g, '')) * (k ? 1000 : 1);
    const unit = (m[6] || m[3] || '').toLowerCase().replace(/\W/g, '');
    return {
      salary: text,
      salary_min: toNumber(m[1], m[2]),
      salary_max: toNumber(m[4], m[5]),
      salary_currency: text.includes('$') ? 'USD' : null,
      salary_unit: SALARY_UNIT_MAP[unit] || null,
    };
  }

  function classifyInsightPills(texts) {
    const result = {};
    for (const text of texts) {
      if (result.salary === undefined && SALARY_PILL.test(text)) {
        Object.assign(result, parseSalaryPill(text));
      } else if (!result.employment_type && EMPLOYMENT_PILL.test(text)) {
        result.employment_type = text;
      } else if (!result.remote && REMOTE_PILL.test(text)) {
        result.remote = text;
      }
    }
    return result;
  }

  function pickHtml(doc, selectors) {
    for (const sel of selectors.split(',').map(s => s.trim())) {
      const h = doc.querySelector(sel)?.innerHTML?.trim();
      if (h) return h;
    }
    return null;
  }

  function pickInnerText(doc, selectors) {
    for (const sel of selectors.split(',').map(s => s.trim())) {
      const el = doc.querySelector(sel);
      const t = (el?.innerText || el?.textContent)?.trim();
      if (t) return t;
    }
    return null;
  }

  function wordCount(str) {
    return str ? str.trim().split(/\s+/).filter(Boolean).length : 0;
  }

  function esc(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function kbSize(str) {
    return str ? Math.round(new Blob([str]).size / 1024) : 0;
  }

  function sleep(ms) {
    return new Promise(r => setTimeout(r, ms));
  }

  // ─── Provider detection ────────────────────────────────────────────────────

  const hostname = window.location.hostname;
  let provider = null;
  for (const [key, p] of Object.entries(PROVIDERS)) {
    if (p.match(hostname)) { provider = { key, ...p }; break; }
  }

  LOG('Provider detected:', provider ? provider.label : 'none — generic fallback');

  // Toolbar badge: lets the user see capture is available without opening
  // the popup or scrolling to the in-page overlay. Fire-and-forget --
  // background.js clears it on every navigation and only this message
  // re-lights it, so a failed send here just means a missing badge, never
  // a stuck one.
  try {
    chrome.runtime.sendMessage({
      type: 'PROVIDER_DETECTED',
      provider: provider ? provider.key : null,
      label: provider ? provider.label : null,
    });
  } catch (_) { /* ignore */ }

  // ─── Capture mode ──────────────────────────────────────────────────────────
  // ?wwr_id=NNN means the Rails app linked us here to enrich a known posting
  // (existing flow, trusted — proceeds regardless of provider match). With no
  // wwr_id we're free-browsing: only proceed on a curated board, OR when this
  // injection came from the "Scan This Page" popup button (manualScan) --
  // this file is only ever injected on other sites via that explicit,
  // one-tab, one-click action, never automatically.

  const captureMode = wwrId ? 'enrich' : 'capture';
  if (captureMode === 'capture' && !provider && !manualScan) return;

  LOG(captureMode === 'enrich'
    ? `Enrichment mode active — Job ID: ${wwrId} | URL: ${window.location.href}`
    : `Capture mode active — provider: ${provider ? provider.label : 'generic (manual scan)'} | URL: ${window.location.href}`);

  // ─── Auto-expand truncated content ────────────────────────────────────────
  //
  // LinkedIn and Indeed truncate the job description behind a "Show more" button.
  // Clicking it before capture ensures the backend and extractor receive the
  // full description rather than a truncated preview.

  const EXPANDERS = {
    linkedin: [
      '.show-more-less-html__button--more',
      '.jobs-description__footer-button',
      'button[aria-label*="show more" i]',
    ],
    indeed: [
      '#ind-job-description-toggle button',
      '.ia-JobDetails-readMore button',
    ],
    greenhouse: [
      'a[data-mapped="true"]',                    // "Read more" link on some listings
      'button.expand-button',
    ],
    lever: [
      '.content-wrapper button[data-qa="show-more"]',
      'button[class*="show-more"]',
    ],
    workday: [
      '[data-automation-id="expandButton"]',
      'button[aria-label*="more" i]',
    ],
    wellfound: [
      'button[data-test="read-more"]',
      'button[class*="readMore"]',
      'button[class*="ReadMore"]',
    ],
  };

  async function expandContent(prov) {
    if (!prov) return;
    const selectors = EXPANDERS[prov.key];
    if (!selectors?.length) return;

    let expanded = false;
    for (const sel of selectors) {
      const btn = document.querySelector(sel);
      // Only click if the button is visible (offsetParent is null for hidden elements)
      if (btn && btn.offsetParent !== null && !btn.disabled) {
        LOG('Auto-expanding truncated description via:', sel);
        btn.click();
        expanded = true;
        // Allow animation/re-render to complete before proceeding
        await sleep(800);
        break;
      }
    }
    if (!expanded) {
      LOG('No truncation expander found (description may already be fully visible)');
    }
  }

  // ─── Configurable API config ───────────────────────────────────────────────
  // Reads apiUrl, apiEmail, apiPassword from chrome.storage.local (set via popup).
  // Falls back to localhost:31000 with no auth if nothing is saved.

  const DEFAULT_API = 'http://localhost:31000';

  async function getApiConfig() {
    return new Promise(resolve => {
      try {
        chrome.storage.local.get(['apiUrl', 'apiEmail', 'apiPassword'], (cfg) => {
          const base = (cfg.apiUrl || DEFAULT_API).replace(/\/$/, '');
          let authHeader = null;
          if (cfg.apiEmail && cfg.apiPassword) {
            authHeader = 'Basic ' + btoa(`${cfg.apiEmail}:${cfg.apiPassword}`);
          }
          resolve({ base, authHeader });
        });
      } catch (_) {
        resolve({ base: DEFAULT_API, authHeader: null });
      }
    });
  }

  // Legacy shim — keep callers that only need the URL working
  async function getApiBase() {
    return (await getApiConfig()).base;
  }

  // ─── API fetch (proxied through background) ────────────────────────────────
  // Content scripts run in the page's own context, and some sites' CSP
  // blocks their fetch() calls entirely (observed on LinkedIn: "TypeError:
  // Failed to fetch"). The background service worker isn't subject to any
  // page's CSP, so all API calls are relayed through it via API_FETCH.

  function apiFetchOnce(url, { method = 'GET', headers = {}, body, timeoutMs = 20000 } = {}) {
    const messagePromise = new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({ type: 'API_FETCH', url, method, headers, body }, response => {
        if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
        else if (!response) reject(new Error('No response from background'));
        else if (response.ok === false && response.error) reject(new Error(response.error));
        else resolve(response);
      });
    });
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Timeout — is Rails running at ${url}?`)), timeoutMs)
    );
    return Promise.race([messagePromise, timeoutPromise]);
  }

  // A transient blip (dev server mid-restart, one slow request stalling the
  // single-process GVL -- both observed live this session) shouldn't force
  // the user to notice a failure and manually retry. GET is always safe to
  // retry; POST is retried too since every POST this extension makes
  // (/api/leads by signature, /api/leads/:id/promote, /api/extraction_rules
  // upsert-by-provider+field) is idempotent server-side, so a retried
  // duplicate is a no-op, not a double-submit.
  const RETRY_DELAYS_MS = [500, 1500];

  async function apiFetch(url, opts = {}) {
    let lastErr;
    for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
      try {
        return await apiFetchOnce(url, opts);
      } catch (err) {
        lastErr = err;
        if (attempt < RETRY_DELAYS_MS.length) {
          LOG_WARN(`API call failed (attempt ${attempt + 1}/${RETRY_DELAYS_MS.length + 1}): ${err.message} — retrying…`);
          await sleep(RETRY_DELAYS_MS[attempt]);
        }
      }
    }
    throw lastErr;
  }

  // ─── Extraction chain ──────────────────────────────────────────────────────

  const Extractor = {

    // ── 1. JSON-LD (Schema.org JobPosting) ──────────────────────────────────
    jsonLd(doc) {
      const scripts = doc.querySelectorAll('script[type="application/ld+json"]');
      for (const script of scripts) {
        try {
          const raw = JSON.parse(script.textContent);
          const candidates = Array.isArray(raw) ? raw : raw['@graph'] ? raw['@graph'] : [raw];

          for (const item of candidates) {
            if (item['@type'] !== 'JobPosting') continue;
            if (!jsonLdMatchesCurrentPage(doc, item)) {
              LOG_WARN(`JSON-LD: skipping unrelated JobPosting "${item.title}" (doesn't match this page)`);
              continue;
            }

            LOG_GRP('JSON-LD JobPosting found', () => console.log(item));
            reportDiag('info', ['Raw JSON-LD JobPosting captured (see detail below)'], item);

            const loc    = item.jobLocation;
            const addr   = Array.isArray(loc) ? loc[0]?.address : loc?.address;
            const locStr = addr
              ? [addr.addressLocality, addr.addressRegion, addr.addressCountry].filter(Boolean).join(', ')
              : null;

            const salary    = item.baseSalary;
            const salaryVal = salary?.value;

            return {
              _method:          'json_ld',
              _confidence:      'high',
              title:             item.title             || null,
              company:           item.hiringOrganization?.name || null,
              company_logo_url:  item.hiringOrganization?.logo || null,
              location:          locStr,
              remote:            item.jobLocationType === 'TELECOMMUTE' || null,
              remote_type:       item.jobLocationType  || null,
              salary_min:        salaryVal?.minValue    || null,
              salary_max:        salaryVal?.maxValue    || null,
              salary_value:      salaryVal?.value       || null,
              salary_currency:   salary?.currency       || null,
              salary_unit:       salaryVal?.unitText    || null,
              employment_type:   item.employmentType    || null,
              posted_at:         item.datePosted        || null,
              valid_through:     item.validThrough      || null,
              apply_url:         item.url || item.sameAs || null,
              industry:          item.industry          || null,
              skills:            item.skills            || null,
              qualifications:    item.qualifications    || null,
              responsibilities:  item.responsibilities  || null,
              benefits:          item.jobBenefits       || null,
              experience:        item.experienceRequirements || null,
              education:         item.educationRequirements  || null,
              description_html:  item.description       || null,
              description_text:  item.description
                ? item.description.replace(/<\/(p|div|h[1-6])>/gi, '\n\n').replace(/<li[^>]*>|<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, ' ')
                    .split('\n').map(line => line.replace(/[ \t]+/g, ' ').trim()).join('\n')
                    .replace(/\n{3,}/g, '\n\n')
                    .trim()
                : null,
            };
          }
        } catch (e) {
          LOG_WARN('JSON-LD parse error:', e.message);
        }
      }
      return null;
    },

    // ── 2. Provider CSS selectors ────────────────────────────────────────────
    css(doc, prov) {
      if (!prov?.extract) return null;
      try {
        const result = prov.extract(doc);
        if (!result.description_html && !result.description_text && !result.title) return null;
        return { _method: 'css', _confidence: 'medium', ...result };
      } catch (e) {
        LOG_WARN('CSS extraction error:', e.message);
        return null;
      }
    },

    // ── 3. Open Graph / Meta tags ────────────────────────────────────────────
    meta(doc) {
      const get = sel => doc.querySelector(sel)?.getAttribute('content')?.trim() || null;
      return {
        _method:          'meta',
        _confidence:      'low',
        title:             get('meta[property="og:title"]') || get('meta[name="title"]'),
        description_text:  get('meta[property="og:description"]') || get('meta[name="description"]'),
        company:           get('meta[property="og:site_name"]'),
        image_url:         get('meta[property="og:image"]'),
        canonical_url:     doc.querySelector('link[rel="canonical"]')?.href || null,
      };
    },

    // ── 4. Generic heuristics ────────────────────────────────────────────────
    generic(doc) {
      const descEl = doc.querySelector(
        'main article, article, [role="main"], main, .job-description, #job-description'
      );
      return {
        _method:          'generic',
        _confidence:      'low',
        title:             doc.querySelector('h1')?.textContent?.trim() || null,
        description_html:  descEl?.innerHTML?.trim() || null,
        description_text:  (descEl?.innerText || descEl?.textContent)?.trim() || null,
      };
    },

    // ── Orchestrate ──────────────────────────────────────────────────────────
    run(doc, prov) {
      LOG('Starting extraction chain…');

      const jsonLd = this.jsonLd(doc);
      if (jsonLd) {
        LOG_OK(`JSON-LD — ${countFields(jsonLd)} fields, ${wordCount(jsonLd.description_text)} desc words`);
      } else {
        LOG_WARN('JSON-LD: no JobPosting schema found on this page');
      }

      const css = this.css(doc, prov);
      if (css) {
        LOG_OK(`CSS (${prov?.label ?? 'none'}) — ${wordCount(css.description_text)} desc words`);
      } else if (prov) {
        LOG_WARN(`CSS: no content matched for ${prov.label}`);
      }

      const meta = this.meta(doc);
      LOG('Meta:', meta.title ? `"${meta.title.substring(0, 40)}"` : 'no title',
        '| canonical:', meta.canonical_url || 'none');

      // Merge: JSON-LD is authoritative for structured fields.
      // CSS description fills in when JSON-LD has no description.
      // Meta fills remaining gaps.
      // Null-safe: a null value in a higher-priority source never clobbers
      // a real value from a lower-priority source.
      // generic() always runs (not just when jsonLd/css are both null) --
      // a CSS tier that finds a title but not a description (e.g. a provider
      // whose selectors match on one SPA view but not another) still "wins"
      // as base, which would otherwise skip generic() and its description
      // entirely even though generic()'s broader selectors might catch it.
      const generic = this.generic(doc);
      const base    = jsonLd || css || generic;
      const merged  = mergeNonNull({}, meta, css, jsonLd, base);

      if (!merged.description_html && css?.description_html) {
        merged.description_html = css.description_html;
        merged.description_text = css.description_text;
        LOG_WARN('Used CSS description as fallback (JSON-LD had no description field)');
      }
      if (!merged.description_html && generic?.description_html) {
        merged.description_html = generic.description_html;
        merged.description_text = generic.description_text;
        LOG_WARN('Used generic description as fallback (JSON-LD/CSS had no description field)');
      }
      if (!merged.canonical_url && meta.canonical_url) {
        merged.canonical_url = meta.canonical_url;
      }

      merged._method     = base._method;
      merged._confidence = base._confidence;

      LOG_GRP('Extraction complete', () => {
        console.log('Method:      ', merged._method);
        console.log('Confidence:  ', merged._confidence);
        console.log('Fields found:', countFields(merged));
        console.log('Desc words:  ', wordCount(merged.description_text));
        console.log('HTML size:   ', kbSize(merged.description_html) + ' kb');
        console.table(
          Object.fromEntries(
            Object.entries(merged)
              .filter(([k]) => !k.startsWith('_') && k !== 'description_html')
              .map(([k, v]) => [k, typeof v === 'string' && v.length > 80 ? v.substring(0, 80) + '…' : v])
          )
        );
      });

      const metaDetail = {
        method: merged._method, confidence: merged._confidence,
        fields_found: countFields(merged), desc_words: wordCount(merged.description_text),
        html_kb: kbSize(merged.description_html),
        fields: Object.fromEntries(
          Object.entries(merged)
            .filter(([k]) => !k.startsWith('_') && k !== 'description_html')
            .map(([k, v]) => [k, typeof v === 'string' && v.length > 80 ? v.substring(0, 80) + '…' : v])
        ),
      };
      reportDiag('info', ['Extraction metadata (see detail below)'], metaDetail);

      const wc = wordCount(merged.description_text);
      if (wc < 50) {
        LOG_WARN(`Low word count (${wc}). Content may still be loading — try waiting and retrying.`);
      }

      return merged;
    },
  };

  function countFields(obj) {
    return Object.entries(obj)
      .filter(([k, v]) => !k.startsWith('_') && v !== null && v !== undefined && v !== '').length;
  }

  // ─── Content readiness (SPA guard) ────────────────────────────────────────

  function waitForContent(selector, timeoutMs) {
    LOG('Waiting for:', selector, `(${timeoutMs}ms max)`);
    return new Promise(resolve => {
      const found = document.querySelector(selector);
      if (found) { LOG_OK('Content already present'); return resolve(found); }

      const observer = new MutationObserver(() => {
        const el = document.querySelector(selector);
        if (el) { observer.disconnect(); LOG_OK('Content appeared (MutationObserver)'); resolve(el); }
      });
      observer.observe(document.documentElement, { childList: true, subtree: true });
      setTimeout(() => {
        observer.disconnect();
        LOG_WARN('Readiness timeout — proceeding with current DOM state');
        resolve(null);
      }, timeoutMs);
    });
  }

  // ─── Overlay ───────────────────────────────────────────────────────────────

  const BADGE = {
    json_ld: { label: 'JSON-LD  ✓', color: '#8aff80', bg: 'rgba(138,255,128,0.15)' },
    css:     { label: 'CSS  ◎',     color: '#ffff80', bg: 'rgba(255,255,128,0.15)' },
    meta:    { label: 'Meta  ◎',    color: '#ffca80', bg: 'rgba(255,202,128,0.15)' },
    generic: { label: 'Generic  ⚠', color: '#ff9580', bg: 'rgba(255,149,128,0.15)'  },
  };

  const overlay = document.createElement('div');
  overlay.id = 'wwr-enrichment-overlay';
  Object.assign(overlay.style, {
    position: 'fixed', top: '20px', right: '20px', zIndex: '2147483647',
    background: '#22212c', color: '#f8f8f2',
    padding: '0', borderRadius: '8px',
    boxShadow: '0 10px 30px rgba(0,0,0,0.6)',
    border: '2px solid #9580ff',
    fontFamily: 'monospace', fontSize: '14px', lineHeight: '1.5',
    width: '300px', userSelect: 'none',
    transition: 'opacity 0.2s',
  });

  overlay.innerHTML = `
    <div id="wwr-header" style="
      padding:9px 12px 8px; background:#454158;
      border-radius:6px 6px 0 0;
      display:flex; justify-content:space-between; align-items:center;
      cursor:move;
    ">
      <span style="font-weight:bold;text-transform:uppercase;letter-spacing:1px;color:#ff80bf;font-size:13px;">
        WWWorkRemote_Ingestion
      </span>
      <div style="display:flex;gap:6px;align-items:center;">
        <button id="wwr-min-btn" title="Minimise"
          style="background:none;border:none;color:#9590c5;cursor:pointer;font-size:15px;line-height:1;padding:0 2px;">−</button>
        <button id="wwr-close-btn" title="Dismiss"
          style="background:none;border:none;color:#9590c5;cursor:pointer;font-size:13px;line-height:1;padding:0 2px;">✕</button>
      </div>
    </div>

    <div id="wwr-body" style="padding:12px 12px 10px;">
      <div style="display:flex;justify-content:space-between;margin-bottom:5px;">
        <span style="color:#9590c5;">${captureMode === 'enrich'
          ? `ID: <span style="color:#8aff80;">#${esc(wwrId)}</span>`
          : '<span id="wwr-lead-status" style="color:#9590c5;">Not yet captured</span>'}</span>
        <span style="color:#9590c5;">Board:
          <span id="wwr-board" style="color:${provider ? '#ffff80' : '#ff9580'};">
            ${esc(provider ? provider.label : 'Unknown')}
          </span>
        </span>
      </div>

      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;min-height:20px;">
        <span id="wwr-badge" style="font-size:12px;padding:2px 6px;border-radius:3px;background:#454158;color:#9590c5;">
          ${captureMode === 'capture' ? 'ready' : 'scanning…'}
        </span>
        <span id="wwr-field-count" style="font-size:12px;color:#9590c5;"></span>
      </div>

      <div id="wwr-preview" style="
        display:none; background:#17161d; border-radius:4px;
        padding:8px 10px; margin-bottom:10px;
        font-size:12px; color:#f8f8f2; line-height:1.8;
        max-height:160px; overflow-y:auto;
      "></div>

      <button id="wwr-capture-btn" style="
        width:100%; padding:10px;
        background:#9580ff; color:#22212c;
        border:none; border-radius:4px;
        font-weight:bold; cursor:pointer; margin-bottom:8px;
        font-family:monospace; font-size:13px; letter-spacing:1px;
      ">${captureMode === 'capture' ? '↗ CAPTURE THIS JOB' : '↗ OPEN REVIEW PANEL'}</button>

      <div id="wwr-status" style="text-align:center;font-size:12px;color:#9590c5;min-height:14px;">
        ${captureMode === 'capture' ? 'Click to capture' : 'Extracting…'}
      </div>

      <div id="wwr-api-indicator" style="text-align:center;font-size:11px;color:#454158;margin-top:5px;">
        → ${DEFAULT_API}
      </div>
    </div>
  `;

  document.body.appendChild(overlay);

  // Populate API indicator from storage
  getApiBase().then(url => {
    const el = document.getElementById('wwr-api-indicator');
    if (el) el.textContent = '→ ' + url;
  });

  // ─── Draggable overlay ─────────────────────────────────────────────────────

  (function makeDraggable() {
    const header = document.getElementById('wwr-header');
    let dragging = false, ox = 0, oy = 0;
    header.addEventListener('mousedown', e => {
      if (e.target.tagName === 'BUTTON') return;
      dragging = true;
      const r = overlay.getBoundingClientRect();
      ox = e.clientX - r.left; oy = e.clientY - r.top;
      overlay.style.right = 'auto';
      e.preventDefault();
    });
    document.addEventListener('mousemove', e => {
      if (!dragging) return;
      overlay.style.left = (e.clientX - ox) + 'px';
      overlay.style.top  = (e.clientY - oy) + 'px';
    });
    document.addEventListener('mouseup', () => { dragging = false; });
  })();

  // ─── Minimise / close ──────────────────────────────────────────────────────

  let minimised = false;
  document.getElementById('wwr-min-btn').addEventListener('click', () => {
    minimised = !minimised;
    document.getElementById('wwr-body').style.display = minimised ? 'none' : 'block';
    document.getElementById('wwr-min-btn').textContent = minimised ? '+' : '−';
  });

  document.getElementById('wwr-close-btn').addEventListener('click', () => {
    overlay.remove();
    LOG('Overlay dismissed by user');
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  function setStatus(msg, color) {
    const el = document.getElementById('wwr-status');
    if (el) { el.textContent = msg; el.style.color = color || '#9590c5'; }
  }

  function setBadge(method, fieldCount) {
    const b  = BADGE[method] || BADGE.generic;
    const el = document.getElementById('wwr-badge');
    if (el) { el.textContent = b.label; el.style.color = b.color; el.style.background = b.bg; }
    const fc = document.getElementById('wwr-field-count');
    if (fc && fieldCount != null) {
      fc.textContent = `${fieldCount} fields`;
      fc.style.color = fieldCount >= 8 ? '#8aff80' : fieldCount >= 4 ? '#ffff80' : '#ff9580';
    }
  }

  function renderPreview(extracted) {
    const el = document.getElementById('wwr-preview');
    if (!el || !extracted) return;

    const row = (label, val, color) => val
      ? `<div><span style="color:#9580ff;min-width:44px;display:inline-block;">${label}</span>` +
        `<span style="color:${color || '#f8f8f2'};">${esc(String(val).substring(0,60))}` +
        `${String(val).length > 60 ? '…' : ''}</span></div>`
      : '';

    const salaryStr  = formatSalary(extracted);
    const remoteStr  = extracted.remote === true  ? 'Remote'
      : extracted.remote === false ? 'On-site'
      : extracted.remote_type || null;
    const wc         = wordCount(extracted.description_text);
    const descColor  = wc > 200 ? '#8aff80' : wc > 50 ? '#ffff80' : '#ff9580';
    const descRow    = `<div><span style="color:#9580ff;min-width:44px;display:inline-block;">Desc.</span>` +
      `<span style="color:${descColor};">${wc > 0
        ? wc + ' words — ' + esc((extracted.description_text || '').substring(0, 45)) + '…'
        : 'not found'
      }</span></div>`;

    const rows = [
      row('Title',  extracted.title),
      row('Co.',    extracted.company),
      row('Loc.',   extracted.location),
      remoteStr ? row('Remote', remoteStr, remoteStr === 'Remote' ? '#8aff80' : '#f8f8f2') : '',
      salaryStr ? row('Pay',    salaryStr, '#8aff80') : '',
      row('Type',   extracted.employment_type ? formatEmploymentType(extracted.employment_type) : null),
      row('Posted', extracted.posted_at),
      row('Exp.',   extracted.experience ? String(extracted.experience).substring(0, 60) : null),
      descRow,
    ].filter(Boolean);

    if (rows.length) {
      el.innerHTML = rows.join('');
      el.style.display = 'block';
    }
  }

  function formatSalary(e) {
    if (!e) return null;
    if (e.salary_min || e.salary_max || e.salary_value) {
      const unit = e.salary_unit
        ? '/' + e.salary_unit.toLowerCase().replace('year','yr').replace('month','mo').replace('hour','hr')
        : '';
      const cur  = e.salary_currency || '';
      const fmt  = n => n >= 1000 ? `${Math.round(n / 1000)}k` : String(n);
      if (e.salary_min && e.salary_max) return `${cur}${fmt(e.salary_min)}–${fmt(e.salary_max)}${unit}`;
      if (e.salary_value)               return `${cur}${fmt(e.salary_value)}${unit}`;
      return `${cur}${fmt(e.salary_min || e.salary_max)}${unit}`;
    }
    return e.salary || null;
  }

  function formatEmploymentType(t) {
    const map = {
      FULL_TIME: 'Full-time', PART_TIME: 'Part-time',
      CONTRACTOR: 'Contract', TEMPORARY: 'Temporary',
      INTERN: 'Internship',  VOLUNTEER: 'Volunteer',
      PER_DIEM: 'Per Diem',  OTHER: 'Other',
    };
    return map[t] || t;
  }

  // ─── Extraction preview ─────────────────────────────────────────────────────
  // Enrich mode: runs immediately on page load (trusted trigger). Capture
  // mode: only runs when the user clicks the overlay button (see below).

  // ─── Learned field overrides ───────────────────────────────────────────────
  // Applies any rules taught via the element picker for this provider,
  // overriding just the matched fields on top of the existing extraction
  // chain. Fails soft -- a network hiccup here should never block extraction.
  async function applyLearnedRules(extracted) {
    const providerKey = provider ? provider.key : 'generic';
    try {
      const { base: apiBase, authHeader } = await getApiConfig();
      const headers = authHeader ? { Authorization: authHeader } : {};
      const { ok, data } = await apiFetch(
        `${apiBase}/api/extraction_rules?provider=${encodeURIComponent(providerKey)}`, { headers }
      );
      if (!ok || !Array.isArray(data)) return;
      for (const rule of data) {
        // One rule's selector shouldn't be able to break the rest -- e.g. an
        // AI-learned selector that echoed an unescaped Tailwind decimal class
        // (gap-2.5 -> .gap-2.5 parses as two chained classes, ".5" being
        // invalid) throws a SyntaxError from querySelector, not just a miss.
        try {
          const text = document.querySelector(rule.selector)?.textContent?.trim();
          if (text) extracted[rule.field_name] = text;
        } catch (ruleErr) {
          LOG_WARN(`Learned rule for "${rule.field_name}" has an invalid selector (non-fatal):`, ruleErr.message);
        }
      }
    } catch (e) {
      LOG_WARN('Learned rules fetch failed (non-fatal):', e.message);
    }
  }

  async function previewExtraction() {
    // Step 1: Auto-expand any truncated content
    await expandContent(provider);

    // Step 2: Wait for SPA to render key elements. A timeout here does NOT
    // mean "not a job page" -- LinkedIn in particular is slow/inconsistent
    // about this selector appearing even on genuine job-detail pages -- so
    // we proceed with whatever the DOM has and let extraction itself decide.
    if (provider?.readySelector) {
      await waitForContent(provider.readySelector, provider.readyTimeout);
    }

    // Step 3: Run extraction chain, apply any taught field overrides, show preview
    const extracted = Extractor.run(document, provider);
    await applyLearnedRules(extracted);

    // Step 3b: In capture mode, bail out only if extraction found essentially
    // nothing -- a far more reliable "is this really a job page" signal than
    // one CSS selector's timing, since JSON-LD/meta/generic fallbacks can
    // still find a title even when the readySelector is slow or stale.
    if (captureMode === 'capture' && !extracted.title && wordCount(extracted.description_text) < 20) {
      LOG_WARN('No title or description found — not a job detail page.');
      return null;
    }

    setBadge(extracted._method, countFields(extracted));
    renderPreview(extracted);
    return extracted;
  }

  let cachedExtraction = null;
  let leadId = null;
  let leadCapturePromise = null;

  if (captureMode === 'enrich') {
    // Trusted flow (user explicitly clicked "Source & Enrich" in the app) —
    // extract and open the panel immediately, same as before.
    previewExtraction().then(e => {
      cachedExtraction = e;
      notifyPanel(e);
    });
  }
  // In capture mode, nothing runs automatically -- extraction, lead capture,
  // and the panel all wait for the manual click below. Free browsing means
  // this content script fires on every matching-hostname page, including
  // search/listing pages, so a silent auto-run was too unreliable in practice.

  const EXTRACTING_PLACEHOLDER = { title: 'Extracting…', description_text: '', _method: 'pending', _confidence: 'low' };
  const NOT_FOUND_PLACEHOLDER = {
    title: '(not found)',
    description_text: 'No job content found on this page.',
    _method: 'pending', _confidence: 'low',
  };

  document.getElementById('wwr-capture-btn').addEventListener('click', () => {
    if (captureMode === 'enrich' || cachedExtraction) {
      notifyPanel(cachedExtraction);
      return;
    }

    // Open the panel synchronously, within this click's gesture window --
    // chrome.sidePanel.open() rejects once any awaited work (extraction can
    // take several seconds) pushes past the gesture's validity. Open first
    // with a loading placeholder, then patch in real data once ready.
    notifyPanel(EXTRACTING_PLACEHOLDER);
    setStatus('Extracting…', '#9580ff');

    previewExtraction().then(e => {
      if (!e) {
        setStatus('No job content found on this page', '#ff9580');
        notifyPanel(NOT_FOUND_PLACEHOLDER, { alreadyOpen: true });
        return;
      }
      cachedExtraction = e;
      captureLead(e);
      notifyPanel(e, { alreadyOpen: true });
    });
  });

  // ─── Open side panel ───────────────────────────────────────────────────────
  // Sends extraction state to the background service worker, which stores it
  // in chrome.storage.session. First call per capture opens the panel
  // (chrome.sidePanel.open); subsequent calls (alreadyOpen) just patch data.

  function notifyPanel(extracted, { alreadyOpen = false } = {}) {
    if (!extracted) return;
    if (!alreadyOpen) setStatus('↗ Opening panel…', '#9580ff');
    chrome.runtime.sendMessage({
      type:       alreadyOpen ? 'UPDATE_PANEL_DATA' : 'OPEN_PANEL',
      mode:       captureMode,
      wwrId,
      leadId,
      extracted,
      provider:   provider ? provider.key : 'generic',
      pageUrl:    window.location.href,
      pageTitle:  document.title,
    }, response => {
      if (chrome.runtime.lastError || !response?.ok) {
        const err = chrome.runtime.lastError?.message || response?.error || 'Could not open panel';
        LOG_WARN('Panel update failed:', err);
        if (!alreadyOpen) setStatus('Panel unavailable — see console', '#ff9580');
      } else if (!alreadyOpen) {
        setStatus('Panel open — review and submit', '#8aff80');
        LOG_OK('Side panel opened');
      }
    });
  }

  // ─── Lead capture (capture mode only) ──────────────────────────────────────
  // Fires the instant a job-detail page is confirmed, well before the user
  // opens the panel. Idempotent server-side on the URL signature.

  function captureLead(extracted) {
    leadCapturePromise = performLeadCapture(extracted);
    return leadCapturePromise;
  }

  async function performLeadCapture(extracted) {
    const { base: apiBase, authHeader } = await getApiConfig();
    const { rawHtml, htmlTruncated } = captureHtmlSnapshot();
    const payload = {
      url:      window.location.href,
      provider: provider ? provider.key : 'generic',
      title:    extracted.title,
      company_name: extracted.company,
      location: extracted.location,
      raw_html: rawHtml,
      discovery: {
        referrer:              document.referrer,
        search_context:        window.location.search,
        extraction_confidence: extracted._confidence,
        extraction_method:     extracted._method,
        field_count:           countFields(extracted),
        html_truncated:        htmlTruncated,
      },
    };

    LOG(`POST → ${apiBase}/api/leads`);
    const headers = { 'Content-Type': 'application/json' };
    if (authHeader) headers['Authorization'] = authHeader;

    try {
      const { ok, status, data } = await apiFetch(`${apiBase}/api/leads`, {
        method: 'POST', headers, body: JSON.stringify(payload),
      });
      if (!ok || !data.success) throw new Error(data.error || `Server error ${status}`);

      leadId = data.id;
      LOG_OK(`Lead captured — #${leadId}`);
      updateLeadStatus('Lead captured ✓', '#8aff80');
    } catch (err) {
      LOG_ERR('Lead capture failed:', err);
      updateLeadStatus('Lead capture failed', '#ff9580');
    }
  }

  function updateLeadStatus(text, color) {
    const el = document.getElementById('wwr-lead-status');
    if (el) { el.textContent = text; el.style.color = color; }
  }

  // ─── Element picker ("Teach the extractor") ────────────────────────────────
  // Activated by a "🎯" button next to a side panel field. Highlights the
  // element under the cursor; a click captures it and reports back via
  // PICKER_RESULT so the panel can send it to Api::ExtractionRulesController
  // for the AI to refine into a reusable per-provider selector.
  const PickerMode = (() => {
    let active = false;
    let fieldName = null;
    let highlightEl = null;
    let hovered = null;

    function ensureHighlight() {
      if (highlightEl) return highlightEl;
      highlightEl = document.createElement('div');
      Object.assign(highlightEl.style, {
        position: 'fixed', pointerEvents: 'none', zIndex: '2147483647',
        border: '2px solid #8aff80', background: 'rgba(138,255,128,0.15)',
        transition: 'all 60ms ease-out', display: 'none',
      });
      document.documentElement.appendChild(highlightEl);
      return highlightEl;
    }

    function onMouseMove(e) {
      const el = document.elementFromPoint(e.clientX, e.clientY);
      if (!el || el === hovered || el === highlightEl) return;
      hovered = el;
      const rect = el.getBoundingClientRect();
      Object.assign(ensureHighlight().style, {
        display: 'block', left: `${rect.left}px`, top: `${rect.top}px`,
        width: `${rect.width}px`, height: `${rect.height}px`,
      });
    }

    function onClick(e) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      const el = hovered || document.elementFromPoint(e.clientX, e.clientY);
      report(el);
      stop();
    }

    function onKeydown(e) {
      if (e.key === 'Escape') { report(null); stop(); }
    }

    function report(el) {
      LOG(el ? `Picker captured element for "${fieldName}"` : `Picker cancelled for "${fieldName}"`);
      chrome.runtime.sendMessage({
        type: 'PICKER_RESULT',
        result: el ? {
          fieldName,
          value: el.textContent?.trim() || '',
          elementHtml: el.outerHTML.slice(0, 4000),
          parentHtml: el.parentElement ? el.parentElement.outerHTML.slice(0, 6000) : '',
          candidateSelector: computeSelector(el),
        } : { fieldName, cancelled: true },
      });
    }

    function start(name) {
      if (active) stop();
      active = true;
      fieldName = name;
      document.body.style.cursor = 'crosshair';
      document.addEventListener('mousemove', onMouseMove, true);
      document.addEventListener('click', onClick, true);
      document.addEventListener('keydown', onKeydown, true);
    }

    function stop() {
      active = false;
      hovered = null;
      document.body.style.cursor = '';
      if (highlightEl) highlightEl.style.display = 'none';
      document.removeEventListener('mousemove', onMouseMove, true);
      document.removeEventListener('click', onClick, true);
      document.removeEventListener('keydown', onKeydown, true);
    }

    return { start };
  })();

  // ─── Message handlers (from background, relayed from side panel) ──────────

  chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {

    // PICKER_START: user clicked "Teach" next to a field in the panel
    if (msg.type === 'PICKER_START') {
      PickerMode.start(msg.fieldName);
      sendResponse({ ok: true });
      return;
    }

    // PANEL_SUBMIT: user clicked Submit in the panel — post to Rails API
    if (msg.type === 'PANEL_SUBMIT') {
      handlePanelSubmit(msg.editedData)
        .then(result => sendResponse(result))
        .catch(err   => sendResponse({ ok: false, error: err.message }));
      return true;
    }

    // REEXTRACT: user clicked "Re-read page" or "Re-read description" in panel
    if (msg.type === 'REEXTRACT') {
      const descOnly = !!msg.descOnly;
      LOG(descOnly ? 'Re-reading description only…' : 'Re-extracting full page…');
      setStatus(descOnly ? '↺ Re-reading description…' : '↺ Re-reading page…', '#9580ff');

      previewExtraction().then(freshExtracted => {
        if (!freshExtracted) {
          sendResponse({ ok: false, error: 'Job content not found on this page.' });
          return;
        }
        cachedExtraction = freshExtracted;
        if (descOnly) {
          // Merge only description fields into existing panel state without clobbering edits
          chrome.runtime.sendMessage({
            type: 'UPDATE_DESCRIPTION',
            description_text: freshExtracted.description_text,
            description_html: freshExtracted.description_html,
          });
        } else {
          notifyPanel(freshExtracted);
        }
        sendResponse({ ok: true });
      }).catch(err => sendResponse({ ok: false, error: err.message }));
      return true;
    }
  });

  // ─── SPA navigation staleness detection ───────────────────────────────────
  // On SPAs (LinkedIn, Indeed), selecting a new job updates the URL without
  // reloading the page. Live-tested: intercepting history.pushState never
  // fired here -- LinkedIn's router bundle already held its own reference to
  // the original pushState before this content script (document_end) ran, so
  // patching it after the fact is a no-op. Polling location.href sidesteps
  // that entirely since it doesn't depend on which function reference the
  // host page happens to call.
  let _lastHref = window.location.href;
  setInterval(() => {
    if (window.location.href !== _lastHref) {
      _lastHref = window.location.href;
      markPanelStale();
    }
  }, 750);

  // Clears the capture-button's memoized extraction/lead so the next click
  // does a fresh capture of whatever posting is on screen now, instead of
  // silently re-submitting the previous posting (the button click handler
  // below short-circuits to cachedExtraction when it's already set).
  function resetForNewPage() {
    cachedExtraction = null;
    leadId = null;
    leadCapturePromise = null;

    const preview = document.getElementById('wwr-preview');
    if (preview) { preview.style.display = 'none'; preview.innerHTML = ''; }

    const badgeEl = document.getElementById('wwr-badge');
    if (badgeEl) {
      badgeEl.textContent = captureMode === 'capture' ? 'ready' : 'scanning…';
      badgeEl.style.background = '#454158';
      badgeEl.style.color = '#9590c5';
    }
    const fc = document.getElementById('wwr-field-count');
    if (fc) fc.textContent = '';

    updateLeadStatus('Not yet captured', '#9590c5');
  }

  function markPanelStale() {
    resetForNewPage();

    const SESSION_KEY = 'wwr_panel_state';
    chrome.storage.session.get(SESSION_KEY, data => {
      const state = data?.[SESSION_KEY];
      if (state && !state.stale) {
        chrome.storage.session.set({ [SESSION_KEY]: { ...state, stale: true } });
        setStatus('⚠ Page navigated — re-read or close', '#ffff80');
        LOG_WARN('SPA navigation detected — panel data may be stale');
      }
    });
  }

  // Max HTML payload size — avoids hitting Rack's body limit on large SPAs
  const HTML_MAX_BYTES = 512 * 1024; // 512 KB

  async function handlePanelSubmit(editedData) {
    if (captureMode === 'capture') {
      await leadCapturePromise;
      if (!leadId) return { ok: false, error: 'Lead capture failed — cannot submit.' };
      return submitPromote(editedData);
    }
    return submitEnrich(editedData);
  }

  function captureHtmlSnapshot() {
    let rawHtml = document.body.innerHTML;
    let htmlTruncated = false;
    if (new Blob([rawHtml]).size > HTML_MAX_BYTES) {
      const enc = new TextEncoder();
      const bytes = enc.encode(rawHtml);
      rawHtml = new TextDecoder().decode(bytes.slice(0, HTML_MAX_BYTES));
      htmlTruncated = true;
    }
    return { rawHtml, htmlTruncated };
  }

  async function submitEnrich(editedData) {
    const { base: apiBase, authHeader } = await getApiConfig();
    const { rawHtml, htmlTruncated } = captureHtmlSnapshot();

    LOG('Panel submit (enrich) — editedData fields:', countFields(editedData),
      '| desc words:', wordCount(editedData.description_text),
      '| html kb:', kbSize(rawHtml), htmlTruncated ? '(truncated)' : '',
      '| api:', apiBase);

    const payload = {
      id: wwrId,
      html: rawHtml,
      html_truncated: htmlTruncated,
      url: window.location.href,
      title: document.title,
      provider: provider ? provider.key : 'generic',
      extracted: editedData,
    };

    return postJson(`${apiBase}/api/job_postings/${wwrId}/enrich`, payload, authHeader,
      data => data.message || `Sync complete — Job #${wwrId} enriched`);
  }

  // ─── Promote (capture mode: Lead → JobPosting) ─────────────────────────────
  // Mirrors JobPostingEnrichment::AttributeBuilder::JSONB_KEYS server-side so
  // the same extracted fields land in JobPosting#data either way.
  const PROMOTE_DATA_KEYS = [
    'salary_min', 'salary_max', 'salary_currency', 'salary_unit', 'salary',
    'employment_type', 'remote', 'experience', 'valid_through',
    'education', 'qualifications', 'responsibilities', 'benefits',
    'company_logo_url', 'industry',
  ];

  function buildPromotePayload(editedData) {
    const data = {};
    for (const key of PROMOTE_DATA_KEYS) {
      if (editedData[key] !== undefined && editedData[key] !== null && editedData[key] !== '') {
        data[key] = editedData[key];
      }
    }
    if (editedData.skills) data.skills = editedData.skills;

    const payload = {
      title: editedData.title,
      location: editedData.location,
      target_url: editedData.apply_url || window.location.href,
      body: editedData.description_text,
      data,
    };
    if (editedData.company_id) {
      payload.company_id = editedData.company_id;
    } else if (editedData.company) {
      payload.company = { name: editedData.company };
    }
    return payload;
  }

  async function submitPromote(editedData) {
    const { base: apiBase, authHeader } = await getApiConfig();

    LOG('Panel submit (capture) — editedData fields:', countFields(editedData), '| api:', apiBase);

    const payload = buildPromotePayload(editedData);
    return postJson(`${apiBase}/api/leads/${leadId}/promote`, payload, authHeader,
      data => `Sync complete — Job #${data.job_posting_id} created`);
  }

  async function postJson(url, payload, authHeader, successMessage) {
    LOG(`POST → ${url}`);
    const headers = { 'Content-Type': 'application/json' };
    if (authHeader) headers['Authorization'] = authHeader;

    try {
      const { ok, status, data } = await apiFetch(url, { method: 'POST', headers, body: JSON.stringify(payload) });
      if (!ok) throw new Error(data.error || `Server error ${status}`);

      const message = successMessage(data);
      LOG_OK(message);
      setStatus('✨ SYNC COMPLETE', '#8aff80');
      return { ok: true, message, leadId: data.lead_id, jobPostingId: data.job_posting_id };
    } catch (err) {
      LOG_ERR('Panel submit failed:', err);
      return { ok: false, error: err.message };
    }
  }

})();

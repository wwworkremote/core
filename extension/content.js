// WWWorkRemote Content Script — Rich Context Extraction
//
// Activated when a job board URL contains ?wwr_id=NNN.
// The Rails app appends this parameter when the user clicks
// SOURCE_ORIGIN_VERIFY_&_ENRICH on a job posting show page.
//
// Extraction priority chain (highest confidence first):
//   1. JSON-LD  Schema.org JobPosting — structured, authoritative, zero selector drift
//   2. Provider CSS selectors         — board-specific, maintained per provider
//   3. Open Graph / Meta tags         — title, description, canonical URL
//   4. Generic heuristics             — <main>, <article>, largest content block
//   5. Raw DOM                        — always captured; backend CSS extractor last resort

(function () {
  'use strict';

  const urlParams = new URLSearchParams(window.location.search);
  const wwrId = urlParams.get('wwr_id');
  if (!wwrId) return;

  // ─── Structured console logger ─────────────────────────────────────────────
  // All logs prefixed [WWWR HH:MM:SS.mmm] — filter DevTools console by [WWWR].

  const ts     = () => new Date().toISOString().slice(11, 23);
  const LOG      = (...a) => console.log(   `%c[WWWR ${ts()}]`,   'color:#bd93f9;font-weight:bold', ...a);
  const LOG_OK   = (...a) => console.log(   `%c[WWWR ${ts()}] ✓`, 'color:#50fa7b;font-weight:bold', ...a);
  const LOG_WARN = (...a) => console.warn(  `%c[WWWR ${ts()}] ⚠`, 'color:#f1fa8c;font-weight:bold', ...a);
  const LOG_ERR  = (...a) => console.error( `%c[WWWR ${ts()}] ✗`, 'color:#ff5555;font-weight:bold', ...a);
  const LOG_GRP  = (label, fn) => {
    console.groupCollapsed(`%c[WWWR] ${label}`, 'color:#6272a4;font-weight:bold');
    fn();
    console.groupEnd();
  };

  LOG('Enrichment mode active — Job ID:', wwrId, '| URL:', window.location.href);

  // ─── Provider definitions ──────────────────────────────────────────────────
  //
  // readySelector  CSS selector whose presence signals the SPA has rendered.
  //                The extension waits for this before capturing (fixes LinkedIn/Indeed timing).
  // readyTimeout   Max ms to wait before proceeding anyway.
  // extract(doc)   Provider-specific CSS extraction. Runs after JSON-LD attempt.

  const PROVIDERS = {

    // ── Job boards ──────────────────────────────────────────────────────────

    linkedin: {
      label: 'LinkedIn',
      match: h => h.includes('linkedin.com'),
      readySelector: '.show-more-less-html__markup, .jobs-description__content, .description__text',
      readyTimeout: 8000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1.top-card-layout__title, h1.jobs-unified-top-card__job-title, h1'),
          company:          pickText(doc, '.topcard__org-name-link, .jobs-unified-top-card__company-name a, .top-card-layout__first-subline a'),
          location:         pickText(doc, '.topcard__flavor--bullet, .jobs-unified-top-card__bullet'),
          posted_at:        pickText(doc, '.posted-time-ago__text, .jobs-unified-top-card__posted-date'),
          job_type:         pickText(doc, '.jobs-unified-top-card__job-insight span'),
          description_html: pickHtml(doc, '.show-more-less-html__markup, .description__text--rich, .jobs-description__content'),
          description_text: pickInnerText(doc, '.description__text, .jobs-description__content'),
        };
      },
    },

    indeed: {
      label: 'Indeed',
      match: h => h.includes('indeed.com'),
      readySelector: '#jobDescriptionText, .jobsearch-JobComponent-description',
      readyTimeout: 6000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1.jobsearch-JobInfoHeader-title, h1'),
          company:          pickText(doc, '[data-company-name="true"], .jobsearch-InlineCompanyRating div'),
          location:         pickText(doc, '.jobsearch-JobInfoHeader-subtitle div:last-child'),
          salary:           pickText(doc, '#salaryInfoAndJobType .attribute_snippet'),
          description_html: pickHtml(doc, '#jobDescriptionText, .jobsearch-JobComponent-description'),
          description_text: pickInnerText(doc, '#jobDescriptionText, .jobsearch-JobComponent-description'),
        };
      },
    },

    adzuna: {
      label: 'Adzuna',
      match: h => h.includes('adzuna.com'),
      readySelector: '.job-description, [class*="JobDescription"]',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1'),
          company:          pickText(doc, '.company, [class*="company-name"]'),
          location:         pickText(doc, '.location, [class*="location"]'),
          salary:           pickText(doc, '.salary, [class*="salary"]'),
          description_html: pickHtml(doc, '.job-description, [class*="JobDescription"]'),
          description_text: pickInnerText(doc, '.job-description, [class*="JobDescription"]'),
        };
      },
    },

    weworkremotely: {
      label: 'WeWorkRemotely',
      match: h => h.includes('weworkremotely.com'),
      readySelector: '.listing-container, .listing__description, #job-listing',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1.listing-header-container, h1'),
          company:          pickText(doc, '.listing-header--company, .company'),
          location:         pickText(doc, '.region, .listing-header--location'),
          salary:           pickText(doc, '.listing-header--salary'),
          description_html: pickHtml(doc, '.listing-container, .listing__description, #job-listing'),
          description_text: pickInnerText(doc, '.listing-container, .listing__description, #job-listing'),
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

    greenhouse: {
      label: 'Greenhouse',
      match: h => h.includes('greenhouse.io'),
      readySelector: '.job__description, #content, .section-wrapper',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1.app-title, h1'),
          company:          pickText(doc, '.company-name, .employer-name'),
          location:         pickText(doc, '.location, .job-location, .office'),
          employment_type:  pickText(doc, '.employment-type'),
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
          company:          pickText(doc, '[data-automation-id="company"], .css-129m7dg'),
          location:         pickText(doc, '[data-automation-id="locations"]'),
          employment_type:  pickText(doc, '[data-automation-id="time"]'),
          description_html: pickHtml(doc, '[data-automation-id="jobPostingDescription"], [data-automation-id="job-posting-details"]'),
          description_text: pickInnerText(doc, '[data-automation-id="jobPostingDescription"], [data-automation-id="job-posting-details"]'),
        };
      },
    },

    ashby: {
      label: 'Ashby',
      match: h => h.includes('ashby.com') || h.includes('ashbyhq.com'),
      readySelector: '[class*="JobPosting"], [class*="jobPosting"], [class*="Description"]',
      readyTimeout: 6000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1'),
          company:          pickText(doc, '[class*="CompanyName"], [class*="companyName"]'),
          location:         pickText(doc, '[class*="Location"], [class*="location"]'),
          employment_type:  pickText(doc, '[class*="EmploymentType"], [class*="employmentType"]'),
          description_html: pickHtml(doc, '[class*="JobPosting-description"], [class*="jobPostingDescription"], [class*="Description"]'),
          description_text: pickInnerText(doc, '[class*="JobPosting-description"], [class*="jobPostingDescription"], [class*="Description"]'),
        };
      },
    },

    smartrecruiters: {
      label: 'SmartRecruiters',
      match: h => h.includes('smartrecruiters.com'),
      readySelector: '.job-description, .details-content, [itemprop="description"]',
      readyTimeout: 5000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1[itemprop="title"], h1.job-title, h1'),
          company:          pickText(doc, '.company-name, [itemprop="name"]'),
          location:         pickText(doc, '.job-location, [itemprop="jobLocation"]'),
          employment_type:  pickText(doc, '.job-type, [itemprop="employmentType"]'),
          description_html: pickHtml(doc, '.job-description, .details-content, [itemprop="description"]'),
          description_text: pickInnerText(doc, '.job-description, .details-content, [itemprop="description"]'),
        };
      },
    },

    wellfound: {
      label: 'Wellfound',
      match: h => h.includes('wellfound.com'),
      readySelector: '[class*="jobDescription"], [class*="JobDescription"], [class*="description"]',
      readyTimeout: 6000,
      extract(doc) {
        return {
          title:            pickText(doc, 'h1, [class*="JobTitle"], [class*="jobTitle"]'),
          company:          pickText(doc, '[class*="StartupName"], [class*="startupName"], [class*="companyName"]'),
          location:         pickText(doc, '[class*="JobLocation"], [class*="jobLocation"], [class*="location"]'),
          salary:           pickText(doc, '[class*="Salary"], [class*="salary"], [class*="compensation"]'),
          description_html: pickHtml(doc, '[class*="jobDescription"], [class*="JobDescription"]'),
          description_text: pickInnerText(doc, '[class*="jobDescription"], [class*="JobDescription"]'),
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
        if (v !== null && v !== undefined) target[k] = v;
        else if (!(k in target))           target[k] = v; // keep first null as placeholder
      }
    }
    return target;
  }

  // ─── DOM helpers ───────────────────────────────────────────────────────────

  function pickText(doc, selectors) {
    for (const sel of selectors.split(',').map(s => s.trim())) {
      const t = doc.querySelector(sel)?.textContent?.trim();
      if (t) return t;
    }
    return null;
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
  // Falls back to localhost:3010 with no auth if nothing is saved.

  const DEFAULT_API = 'http://localhost:3010';

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

            LOG_GRP('JSON-LD JobPosting found', () => console.log(item));

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
                ? item.description.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
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
      const base   = jsonLd || css || this.generic(doc);
      const merged = mergeNonNull({}, meta, css, jsonLd, base);

      if (!merged.description_html && css?.description_html) {
        merged.description_html = css.description_html;
        merged.description_text = css.description_text;
        LOG_WARN('Used CSS description as fallback (JSON-LD had no description field)');
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
    json_ld: { label: 'JSON-LD  ✓', color: '#50fa7b', bg: 'rgba(80,250,123,0.15)' },
    css:     { label: 'CSS  ◎',     color: '#f1fa8c', bg: 'rgba(241,250,140,0.15)' },
    meta:    { label: 'Meta  ◎',    color: '#ffb86c', bg: 'rgba(255,184,108,0.15)' },
    generic: { label: 'Generic  ⚠', color: '#ff5555', bg: 'rgba(255,85,85,0.15)'  },
  };

  const overlay = document.createElement('div');
  overlay.id = 'wwr-enrichment-overlay';
  Object.assign(overlay.style, {
    position: 'fixed', top: '20px', right: '20px', zIndex: '2147483647',
    background: '#282a36', color: '#f8f8f2',
    padding: '0', borderRadius: '8px',
    boxShadow: '0 10px 30px rgba(0,0,0,0.6)',
    border: '2px solid #bd93f9',
    fontFamily: 'monospace', fontSize: '12px', lineHeight: '1.5',
    width: '300px', userSelect: 'none',
    transition: 'opacity 0.2s',
  });

  overlay.innerHTML = `
    <div id="wwr-header" style="
      padding:9px 12px 8px; background:#44475a;
      border-radius:6px 6px 0 0;
      display:flex; justify-content:space-between; align-items:center;
      cursor:move;
    ">
      <span style="font-weight:bold;text-transform:uppercase;letter-spacing:1px;color:#ff79c6;font-size:11px;">
        Synthesis_Link
      </span>
      <div style="display:flex;gap:6px;align-items:center;">
        <button id="wwr-min-btn" title="Minimise"
          style="background:none;border:none;color:#6272a4;cursor:pointer;font-size:15px;line-height:1;padding:0 2px;">−</button>
        <button id="wwr-close-btn" title="Dismiss"
          style="background:none;border:none;color:#6272a4;cursor:pointer;font-size:13px;line-height:1;padding:0 2px;">✕</button>
      </div>
    </div>

    <div id="wwr-body" style="padding:12px 12px 10px;">
      <div style="display:flex;justify-content:space-between;margin-bottom:5px;">
        <span style="color:#6272a4;">ID: <span style="color:#50fa7b;">#${esc(wwrId)}</span></span>
        <span style="color:#6272a4;">Board:
          <span id="wwr-board" style="color:${provider ? '#f1fa8c' : '#ff5555'};">
            ${esc(provider ? provider.label : 'Unknown')}
          </span>
        </span>
      </div>

      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;min-height:20px;">
        <span id="wwr-badge" style="font-size:10px;padding:2px 6px;border-radius:3px;background:#44475a;color:#6272a4;">
          scanning…
        </span>
        <span id="wwr-field-count" style="font-size:10px;color:#6272a4;"></span>
      </div>

      <div id="wwr-preview" style="
        display:none; background:#1e2029; border-radius:4px;
        padding:8px 10px; margin-bottom:10px;
        font-size:10px; color:#f8f8f2; line-height:1.8;
        max-height:160px; overflow-y:auto;
      "></div>

      <button id="wwr-capture-btn" style="
        width:100%; padding:10px;
        background:#bd93f9; color:#282a36;
        border:none; border-radius:4px;
        font-weight:bold; cursor:pointer; margin-bottom:8px;
        font-family:monospace; font-size:11px; letter-spacing:1px;
      ">↗ OPEN REVIEW PANEL</button>

      <div id="wwr-status" style="text-align:center;font-size:10px;color:#6272a4;min-height:14px;">
        Extracting…
      </div>

      <div id="wwr-api-indicator" style="text-align:center;font-size:9px;color:#44475a;margin-top:5px;">
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
    if (el) { el.textContent = msg; el.style.color = color || '#6272a4'; }
  }

  function setBadge(method, fieldCount) {
    const b  = BADGE[method] || BADGE.generic;
    const el = document.getElementById('wwr-badge');
    if (el) { el.textContent = b.label; el.style.color = b.color; el.style.background = b.bg; }
    const fc = document.getElementById('wwr-field-count');
    if (fc && fieldCount != null) {
      fc.textContent = `${fieldCount} fields`;
      fc.style.color = fieldCount >= 8 ? '#50fa7b' : fieldCount >= 4 ? '#f1fa8c' : '#ff5555';
    }
  }

  function renderPreview(extracted) {
    const el = document.getElementById('wwr-preview');
    if (!el || !extracted) return;

    const row = (label, val, color) => val
      ? `<div><span style="color:#bd93f9;min-width:44px;display:inline-block;">${label}</span>` +
        `<span style="color:${color || '#f8f8f2'};">${esc(String(val).substring(0,60))}` +
        `${String(val).length > 60 ? '…' : ''}</span></div>`
      : '';

    const salaryStr  = formatSalary(extracted);
    const remoteStr  = extracted.remote === true  ? 'Remote'
      : extracted.remote === false ? 'On-site'
      : extracted.remote_type || null;
    const wc         = wordCount(extracted.description_text);
    const descColor  = wc > 200 ? '#50fa7b' : wc > 50 ? '#f1fa8c' : '#ff5555';
    const descRow    = `<div><span style="color:#bd93f9;min-width:44px;display:inline-block;">Desc.</span>` +
      `<span style="color:${descColor};">${wc > 0
        ? wc + ' words — ' + esc((extracted.description_text || '').substring(0, 45)) + '…'
        : 'not found'
      }</span></div>`;

    const rows = [
      row('Title',  extracted.title),
      row('Co.',    extracted.company),
      row('Loc.',   extracted.location),
      remoteStr ? row('Remote', remoteStr, remoteStr === 'Remote' ? '#50fa7b' : '#f8f8f2') : '',
      salaryStr ? row('Pay',    salaryStr, '#50fa7b') : '',
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

  // ─── Pre-extraction preview (fires immediately on page load) ───────────────

  async function previewExtraction() {
    // Step 1: Auto-expand any truncated content
    await expandContent(provider);

    // Step 2: Wait for SPA to render key elements
    if (provider?.readySelector) {
      await waitForContent(provider.readySelector, provider.readyTimeout);
    }

    // Step 3: Run extraction chain and show preview
    const extracted = Extractor.run(document, provider);
    setBadge(extracted._method, countFields(extracted));
    renderPreview(extracted);
    return extracted;
  }

  let cachedExtraction = null;

  // Run extraction then auto-open the panel
  previewExtraction().then(e => {
    cachedExtraction = e;
    notifyPanel(e);
  });

  // Manual trigger — opens/re-opens the panel (fallback if auto-open fails,
  // or if user closed the panel and wants it back)
  document.getElementById('wwr-capture-btn').addEventListener('click', () => {
    notifyPanel(cachedExtraction);
  });

  // ─── Open side panel ───────────────────────────────────────────────────────
  // Sends extraction state to the background service worker, which stores it
  // in chrome.storage.session and calls chrome.sidePanel.open({ tabId }).
  // Requires Chrome 116+ for auto-open without user gesture.

  function notifyPanel(extracted) {
    if (!extracted) return;
    setStatus('↗ Opening panel…', '#bd93f9');
    chrome.runtime.sendMessage({
      type:       'OPEN_PANEL',
      wwrId,
      extracted,
      provider:   provider ? provider.key : 'generic',
      pageUrl:    window.location.href,
      pageTitle:  document.title,
    }, response => {
      if (chrome.runtime.lastError || !response?.ok) {
        const err = chrome.runtime.lastError?.message || response?.error || 'Could not open panel';
        LOG_WARN('Panel open failed:', err);
        setStatus('Panel unavailable — see console', '#ff5555');
      } else {
        setStatus('Panel open — review and submit', '#50fa7b');
        LOG_OK('Side panel opened');
      }
    });
  }

  // ─── Message handlers (from background, relayed from side panel) ──────────

  chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {

    // PANEL_SUBMIT: user clicked Submit in the panel — post to Rails API
    if (msg.type === 'PANEL_SUBMIT') {
      handlePanelSubmit(msg.editedData, msg.wwrId)
        .then(result => sendResponse(result))
        .catch(err   => sendResponse({ ok: false, error: err.message }));
      return true;
    }

    // REEXTRACT: user clicked "Re-read page" or "Re-read description" in panel
    if (msg.type === 'REEXTRACT') {
      const descOnly = !!msg.descOnly;
      LOG(descOnly ? 'Re-reading description only…' : 'Re-extracting full page…');
      setStatus(descOnly ? '↺ Re-reading description…' : '↺ Re-reading page…', '#bd93f9');

      previewExtraction().then(freshExtracted => {
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
  // On SPAs (LinkedIn, Indeed), navigating to a new job does not reload the
  // page. Intercept history.pushState so the panel can show a staleness banner.

  const _originalPushState = history.pushState.bind(history);
  history.pushState = function (...args) {
    _originalPushState(...args);
    markPanelStale();
  };
  window.addEventListener('popstate', markPanelStale);

  function markPanelStale() {
    const SESSION_KEY = 'wwr_panel_state';
    chrome.storage.session.get(SESSION_KEY, data => {
      const state = data?.[SESSION_KEY];
      if (state && !state.stale) {
        chrome.storage.session.set({ [SESSION_KEY]: { ...state, stale: true } });
        setStatus('⚠ Page navigated — re-read or close', '#f1fa8c');
        LOG_WARN('SPA navigation detected — panel data may be stale');
      }
    });
  }

  // Max HTML payload size — avoids hitting Rack's body limit on large SPAs
  const HTML_MAX_BYTES = 512 * 1024; // 512 KB

  async function handlePanelSubmit(editedData, id) {
    const { base: apiBase, authHeader } = await getApiConfig();

    // Truncate DOM snapshot if oversized
    let rawHtml = document.body.innerHTML;
    let htmlTruncated = false;
    if (new Blob([rawHtml]).size > HTML_MAX_BYTES) {
      const enc = new TextEncoder();
      const bytes = enc.encode(rawHtml);
      rawHtml = new TextDecoder().decode(bytes.slice(0, HTML_MAX_BYTES));
      htmlTruncated = true;
    }

    LOG('Panel submit — editedData fields:', countFields(editedData),
      '| desc words:', wordCount(editedData.description_text),
      '| html kb:', kbSize(rawHtml), htmlTruncated ? '(truncated)' : '',
      '| api:', apiBase);

    const payload = {
      id,
      html:      rawHtml,
      html_truncated: htmlTruncated,
      url:       window.location.href,
      title:     document.title,
      provider:  provider ? provider.key : 'generic',
      extracted: editedData,
    };

    LOG(`POST → ${apiBase}/api/job_postings/${id}/enrich`);

    const headers = { 'Content-Type': 'application/json' };
    if (authHeader) headers['Authorization'] = authHeader;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20000);

    try {
      const response = await fetch(`${apiBase}/api/job_postings/${id}/enrich`, {
        method:  'POST',
        headers,
        body:    JSON.stringify(payload),
        signal:  controller.signal,
      });
      clearTimeout(timer);

      let data = {};
      try { data = await response.json(); } catch (_) {}

      if (response.ok) {
        LOG_OK(`Sync complete — Job #${id} enriched`);
        setStatus('✨ SYNC COMPLETE', '#50fa7b');
        return { ok: true, message: data.message };
      } else {
        throw new Error(data.error || `Server error ${response.status}`);
      }
    } catch (err) {
      clearTimeout(timer);
      const msg = err.name === 'AbortError'
        ? `Timeout — is Rails running at ${apiBase}?`
        : err.message;
      LOG_ERR('Panel submit failed:', err);
      return { ok: false, error: msg };
    }
  }

})();

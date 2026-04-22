// sidepanel.js — WWWorkRemote Review Panel
'use strict';

const SESSION_KEY = 'wwr_panel_state';

// ── Field map ──────────────────────────────────────────────────────────────
// Maps form input IDs → extracted object key(s). First non-empty value wins.
const FIELD_MAP = {
  'f-title':           ['title'],
  'f-company':         ['company'],
  'f-location':        ['location'],
  'f-remote':          ['remote'],
  'f-employment-type': ['employment_type'],
  'f-experience':      ['experience'],
  'f-apply-url':       ['apply_url'],   // canonical_url intentionally excluded
  'f-salary-min':      ['salary_min'],
  'f-salary-max':      ['salary_max'],
  'f-salary-currency': ['salary_currency'],
  'f-salary-unit':     ['salary_unit'],
  'f-salary-raw':      ['salary'],
  'f-description':     ['description_text'],
  'f-posted-at':       ['posted_at'],
  'f-valid-through':   ['valid_through'],
  'f-skills':          ['skills', 'tags'],
  'f-education':       ['education'],
  'f-qualifications':  ['qualifications'],
  'f-responsibilities':['responsibilities'],
  'f-benefits':        ['benefits'],
};

const REQUIRED = new Set(['f-title']);

// ── Flexible date parser ───────────────────────────────────────────────────
// Handles ISO dates, timestamps, relative strings ("3 days ago", "today"),
// ordinals ("Sept. 9th"), and incomplete dates (no year → current year).
// Returns YYYY-MM-DD string or '' if unparseable.

function parseDateFlexible(val) {
  if (!val) return '';
  const str = String(val).trim();
  if (!str) return '';

  const now  = new Date();
  const yyyy = now.getFullYear();

  // Already YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(str)) return str;

  // ISO 8601 with time component
  if (/^\d{4}-\d{2}-\d{2}T/.test(str)) return str.slice(0, 10);

  // Unix timestamp (ms or s)
  if (/^\d{10,13}$/.test(str)) {
    const ms = str.length === 13 ? +str : +str * 1000;
    const d  = new Date(ms);
    if (!isNaN(d)) return d.toISOString().slice(0, 10);
  }

  const lower = str.toLowerCase().replace(/\s+/g, ' ').trim();

  // Relative — today / just posted
  if (/^(today|just now|just posted|active today)$/.test(lower))
    return now.toISOString().slice(0, 10);

  // yesterday
  if (/^yesterday$/.test(lower)) {
    const d = new Date(now); d.setDate(d.getDate() - 1);
    return d.toISOString().slice(0, 10);
  }

  // "N days ago" / "N day ago"
  const daysAgo = lower.match(/^(\d+)\s+days?\s+ago$/);
  if (daysAgo) {
    const d = new Date(now); d.setDate(d.getDate() - parseInt(daysAgo[1]));
    return d.toISOString().slice(0, 10);
  }

  // "N weeks ago"
  const weeksAgo = lower.match(/^(\d+)\s+weeks?\s+ago$/);
  if (weeksAgo) {
    const d = new Date(now); d.setDate(d.getDate() - parseInt(weeksAgo[1]) * 7);
    return d.toISOString().slice(0, 10);
  }

  // "N months ago"
  const monthsAgo = lower.match(/^(\d+)\s+months?\s+ago$/);
  if (monthsAgo) {
    const d = new Date(now); d.setMonth(d.getMonth() - parseInt(monthsAgo[1]));
    return d.toISOString().slice(0, 10);
  }

  // Normalise the string for native Date parsing:
  //   ordinals  : "9th" → "9", "21st" → "21"
  //   abbrev.   : "Sept." → "Sep", "Feb." → "Feb", etc.
  const norm = str
    .replace(/(\d+)\s*(st|nd|rd|th)\b/gi, '$1')
    .replace(/\bsept?\b\.?/gi,  'Sep')
    .replace(/\bjan\.?\b/gi,    'Jan').replace(/\bfeb\.?\b/gi,    'Feb')
    .replace(/\bmar\.?\b/gi,    'Mar').replace(/\bapr\.?\b/gi,    'Apr')
    .replace(/\bjun\.?\b/gi,    'Jun').replace(/\bjul\.?\b/gi,    'Jul')
    .replace(/\baug\.?\b/gi,    'Aug').replace(/\boct\.?\b/gi,    'Oct')
    .replace(/\bnov\.?\b/gi,    'Nov').replace(/\bdec\.?\b/gi,    'Dec')
    .trim();

  // If no four-digit year is present, append current year before parsing
  const hasYear = /\b(19|20)\d{2}\b/.test(norm);
  const candidate = hasYear ? norm : `${norm} ${yyyy}`;

  const parsed = new Date(candidate);
  if (!isNaN(parsed.getTime())) return parsed.toISOString().slice(0, 10);

  return ''; // unparseable — leave empty for manual entry
}

// ── Helpers ────────────────────────────────────────────────────────────────

function coalesce(obj, ...keys) {
  for (const k of keys) {
    const v = obj[k];
    if (v !== null && v !== undefined && v !== '') return v;
  }
  return null;
}

function wordCount(str) {
  return str ? str.trim().split(/\s+/).filter(Boolean).length : 0;
}

function tagsToString(val) {
  if (Array.isArray(val)) return val.join(', ');
  if (typeof val === 'string') return val;
  return '';
}

function normalizeEmploymentType(val) {
  if (!val) return '';
  const map = {
    'full-time': 'FULL_TIME', 'full_time': 'FULL_TIME', 'fulltime': 'FULL_TIME', 'full time': 'FULL_TIME',
    'part-time': 'PART_TIME', 'part_time': 'PART_TIME', 'parttime': 'PART_TIME', 'part time': 'PART_TIME',
    'contract':  'CONTRACTOR', 'contractor': 'CONTRACTOR', 'freelance': 'CONTRACTOR', 'consulting': 'CONTRACTOR',
    'temporary': 'TEMPORARY', 'temp': 'TEMPORARY',
    'intern':    'INTERN',    'internship': 'INTERN',
    'volunteer': 'VOLUNTEER',
    'other':     'OTHER',
    'permanent': 'FULL_TIME',
  };
  const key = val.toLowerCase().replace(/[-_]/g, ' ').trim();
  return map[key] || val.toUpperCase();
}

// ── Visibility helpers ─────────────────────────────────────────────────────

function showPanel() {
  document.getElementById('empty-state').style.display = 'none';
  document.getElementById('header').style.display      = '';
  document.getElementById('form-body').style.display   = '';
  document.getElementById('footer').style.display      = '';
}

function showEmpty() {
  document.getElementById('empty-state').style.display = 'flex';
  document.getElementById('header').style.display      = 'none';
  document.getElementById('form-body').style.display   = 'none';
  document.getElementById('footer').style.display      = 'none';
  document.getElementById('stale-banner').style.display = 'none';
}

// ── Confidence badge ──────────────────────────────────────────────────────

const CONFIDENCE = {
  json_ld: { label: 'JSON-LD ✓', color: '#282a36', bg: '#50fa7b' },
  css:     { label: 'CSS ◎',     color: '#282a36', bg: '#f1fa8c' },
  meta:    { label: 'Meta ◎',    color: '#282a36', bg: '#ffb86c' },
  generic: { label: 'Generic ⚠', color: '#f8f8f2', bg: '#ff5555' },
};

function updateConfidenceBadge(method) {
  const el = document.getElementById('confidence-badge');
  if (!el) return;
  const s = CONFIDENCE[method] || CONFIDENCE.generic;
  el.textContent        = s.label;
  el.style.color        = s.color;
  el.style.background   = s.bg;
  el.style.padding      = '1px 7px';
  el.style.borderRadius = '3px';
}

// ── Source dot + field state ──────────────────────────────────────────────

function markSource(srcId, found) {
  const dot = document.getElementById(srcId);
  if (!dot) return;
  dot.classList.toggle('found',   !!found);
  dot.classList.toggle('missing', !found);
  dot.title = found ? 'Extracted from page' : 'Not found — enter manually';
}

function applyFieldState(fieldId, inputId) {
  const field = document.getElementById(fieldId);
  const input = document.getElementById(inputId);
  if (!field || !input) return;
  const hasVal = input.type === 'checkbox'
    ? input.checked
    : input.value.trim() !== '';
  field.classList.remove('filled', 'empty', 'empty-required');
  if (hasVal)                       field.classList.add('filled');
  else if (REQUIRED.has(inputId))   field.classList.add('empty-required');
  else                              field.classList.add('empty');
}

// ── Set value helper ──────────────────────────────────────────────────────

function setVal(inputId, value, fieldId, srcId) {
  const el = document.getElementById(inputId);
  if (!el) return;
  const hasVal = value !== null && value !== undefined && value !== '';
  el.value = hasVal ? String(value) : '';
  if (srcId)  markSource(srcId, hasVal);
  if (fieldId) applyFieldState(fieldId, inputId);
}

// ── Board label ───────────────────────────────────────────────────────────

const BOARD_LABELS = {
  linkedin: 'LinkedIn', indeed: 'Indeed', adzuna: 'Adzuna',
  weworkremotely: 'WeWorkRemotely', remoteok: 'RemoteOK',
  greenhouse: 'Greenhouse', lever: 'Lever', workday: 'Workday',
  ashby: 'Ashby', smartrecruiters: 'SmartRecruiters', wellfound: 'Wellfound',
};

// ── Main populate ─────────────────────────────────────────────────────────

let currentState = null;

function populateForm(state) {
  currentState = state;
  const e = state.extracted || {};

  showPanel();

  // Staleness banner
  const banner = document.getElementById('stale-banner');
  if (state.stale) {
    banner.style.display = 'flex';
  } else {
    banner.style.display = 'none';
  }

  // Header
  document.getElementById('hdr-id').textContent    = state.wwrId || '—';
  document.getElementById('hdr-board').textContent = BOARD_LABELS[state.provider] || state.provider || '—';
  updateConfidenceBadge(e._method);

  // ── Core fields ───────────────────────────────────────────────────────────
  setVal('f-title',   coalesce(e, 'title'),   'fld-title',   'src-title');
  setVal('f-company', coalesce(e, 'company'), 'fld-company', 'src-company');
  setVal('f-location',coalesce(e, 'location'),'fld-location','src-location');

  // Remote checkbox
  const remoteVal     = coalesce(e, 'remote');
  const remoteChecked = remoteVal === true || remoteVal === 'true' ||
    (typeof remoteVal === 'string' && /telecommute|remote/i.test(remoteVal));
  const remoteEl = document.getElementById('f-remote');
  remoteEl.checked = remoteChecked;
  markSource('src-remote', remoteVal !== null && remoteVal !== undefined);
  applyFieldState('fld-remote', 'f-remote');
  document.getElementById('remote-label').textContent =
    remoteChecked ? '✓ Remote position' : 'Remote position';

  // ── Employment type ───────────────────────────────────────────────────────
  const rawType  = coalesce(e, 'employment_type');
  const normType = normalizeEmploymentType(rawType || '');
  const sel      = document.getElementById('f-employment-type');
  const matched  = [...sel.options].some(o => o.value === normType);
  sel.value = matched ? normType : '';
  if (!matched && rawType) {
    sel.add(new Option(rawType, rawType));
    sel.value = rawType;
  }
  markSource('src-employment-type', !!rawType);
  applyFieldState('fld-employment-type', 'f-employment-type');

  // ── Experience ────────────────────────────────────────────────────────────
  const expRaw = coalesce(e, 'experience');
  setVal('f-experience',
    typeof expRaw === 'string' ? expRaw : (expRaw ? String(expRaw) : null),
    'fld-experience', 'src-experience');

  // ── Apply URL (no canonical_url fallback) ─────────────────────────────────
  const applyUrl = coalesce(e, 'apply_url');
  setVal('f-apply-url', applyUrl, 'fld-apply-url', 'src-apply-url');
  const applyLink = document.getElementById('apply-link');
  if (applyUrl) { applyLink.href = applyUrl; applyLink.style.display = 'block'; }
  else          { applyLink.style.display = 'none'; }

  // ── Salary ────────────────────────────────────────────────────────────────
  const hasStructured = !!(coalesce(e, 'salary_min') || coalesce(e, 'salary_max') || coalesce(e, 'salary_value'));
  setVal('f-salary-min', coalesce(e, 'salary_min'), null, null);
  setVal('f-salary-max', coalesce(e, 'salary_max'), null, null);

  // Currency
  const cur    = coalesce(e, 'salary_currency') || '';
  const curSel = document.getElementById('f-salary-currency');
  if (![...curSel.options].some(o => o.value === cur) && cur) curSel.add(new Option(cur, cur));
  curSel.value = cur;

  // Unit
  const unitRaw  = (coalesce(e, 'salary_unit') || '').toUpperCase()
    .replace('ANNUAL', 'YEAR').replace('YEARLY', 'YEAR')
    .replace('MONTHLY', 'MONTH').replace('HOURLY', 'HOUR');
  document.getElementById('f-salary-unit').value =
    ['YEAR','MONTH','HOUR'].includes(unitRaw) ? unitRaw : '';

  // Raw salary fallback (only show if no structured data)
  setVal('f-salary-raw', hasStructured ? null : coalesce(e, 'salary'), null, null);

  const hasSalaryAny = hasStructured || !!coalesce(e, 'salary');
  markSource('src-salary', hasSalaryAny);
  applyFieldState('fld-salary-range', 'f-salary-min');

  // ── Description ───────────────────────────────────────────────────────────
  const rawDesc  = coalesce(e, 'description_text', 'description_html');
  const cleanDesc = rawDesc
    ? rawDesc.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
    : '';
  setVal('f-description', cleanDesc || null, 'fld-description', 'src-description');
  updateWordCount();

  // ── Dates ─────────────────────────────────────────────────────────────────
  populateDateField('f-posted-at',   'fld-posted-at',   'src-posted-at',
                    'posted-at-raw',    coalesce(e, 'posted_at'));
  populateDateField('f-valid-through','fld-valid-through','src-valid-through',
                    'valid-through-raw', coalesce(e, 'valid_through'));

  // ── Skills ────────────────────────────────────────────────────────────────
  setVal('f-skills', tagsToString(coalesce(e, 'skills', 'tags')) || null,
         'fld-skills', 'src-skills');

  // ── Additional details ────────────────────────────────────────────────────
  populateTextarea('f-education',       'fld-education',       'src-education',       coalesce(e, 'education'));
  populateTextarea('f-qualifications',  'fld-qualifications',  'src-qualifications',  coalesce(e, 'qualifications'));
  populateTextarea('f-responsibilities','fld-responsibilities', 'src-responsibilities',coalesce(e, 'responsibilities'));
  populateTextarea('f-benefits',        'fld-benefits',        'src-benefits',        coalesce(e, 'benefits'));

  // Auto-open additional details section if any field was extracted
  const hasAdditional = !!(coalesce(e, 'education') || coalesce(e, 'qualifications') ||
                            coalesce(e, 'responsibilities') || coalesce(e, 'benefits'));
  if (hasAdditional) openDetailsSection();

  // ── Summary ───────────────────────────────────────────────────────────────
  const filled  = countFilledFields();
  const total   = Object.keys(FIELD_MAP).length;
  const missing = total - filled;
  document.getElementById('hdr-filled').textContent  = filled;
  const missingEl = document.getElementById('hdr-missing');
  missingEl.textContent = missing > 0 ? `${missing} to fill in` : 'all fields extracted';
  missingEl.style.color = missing > 0 ? 'var(--yellow)' : 'var(--green)';

  // Enable submit
  const btn = document.getElementById('submit-btn');
  btn.disabled        = false;
  btn.textContent     = 'Submit to WWWorkRemote';
  btn.style.background = '';
  setStatus('Ready — review fields and submit');
}

// ── Date field helper (shows original string when date can't parse) ────────

function populateDateField(inputId, fieldId, srcId, rawDisplayId, rawVal) {
  const parsed = parseDateFlexible(rawVal);
  const input  = document.getElementById(inputId);
  const rawEl  = document.getElementById(rawDisplayId);
  if (!input) return;

  input.value = parsed;
  markSource(srcId, !!rawVal);
  applyFieldState(fieldId, inputId);

  // Show original string when it couldn't be fully parsed to help manual entry
  if (rawEl) {
    if (rawVal && !parsed) {
      rawEl.textContent = `Original: "${rawVal}" — enter date manually`;
      rawEl.style.color = 'var(--yellow)';
    } else if (rawVal && parsed && rawVal !== parsed) {
      rawEl.textContent = `Parsed from: "${rawVal}"`;
      rawEl.style.color = 'var(--comment)';
    } else {
      rawEl.textContent = '';
    }
  }
}

// ── Textarea helper (for additional details fields) ────────────────────────

function populateTextarea(inputId, fieldId, srcId, value) {
  const el = document.getElementById(inputId);
  if (!el) return;
  const hasVal = value !== null && value !== undefined && value !== '';
  el.value = hasVal ? String(value) : '';
  markSource(srcId, hasVal);
  applyFieldState(fieldId, inputId);
}

// ── Additional details section toggle ─────────────────────────────────────

function openDetailsSection() {
  const body   = document.getElementById('details-body');
  const toggle = document.getElementById('details-toggle');
  if (!body || !toggle) return;
  body.style.display   = 'block';
  toggle.textContent   = '▾ Hide extracted details';
}

document.getElementById('details-toggle').addEventListener('click', () => {
  const body   = document.getElementById('details-body');
  const toggle = document.getElementById('details-toggle');
  const open   = body.style.display !== 'none';
  body.style.display = open ? 'none' : 'block';
  toggle.textContent = open
    ? '▸ Show extracted details (education, qualifications, benefits…)'
    : '▾ Hide extracted details';
});

// ── Word count ────────────────────────────────────────────────────────────

function updateWordCount() {
  const ta = document.getElementById('f-description');
  const wc = wordCount(ta?.value || '');
  const el = document.getElementById('desc-meta');
  if (!el) return;
  el.textContent = `${wc} words`;
  el.style.color = wc > 200 ? 'var(--green)' : wc > 50 ? 'var(--yellow)' : 'var(--red)';
}

document.getElementById('f-description').addEventListener('input', updateWordCount);

// ── Apply URL live update ──────────────────────────────────────────────────

document.getElementById('f-apply-url').addEventListener('input', function () {
  const link = document.getElementById('apply-link');
  if (this.value.trim()) { link.href = this.value.trim(); link.style.display = 'block'; }
  else                   { link.style.display = 'none'; }
});

// ── Remote checkbox ────────────────────────────────────────────────────────

document.getElementById('f-remote').addEventListener('change', function () {
  document.getElementById('remote-label').textContent =
    this.checked ? '✓ Remote position' : 'Remote position';
});

// ── Count filled fields ────────────────────────────────────────────────────

function countFilledFields() {
  let n = 0;
  for (const id of Object.keys(FIELD_MAP)) {
    const el = document.getElementById(id);
    if (!el) continue;
    if (el.type === 'checkbox' ? el.checked : el.value?.trim()) n++;
  }
  return n;
}

// ── Status line ───────────────────────────────────────────────────────────

function setStatus(msg, color) {
  const el = document.getElementById('status-line');
  if (!el) return;
  el.textContent = msg;
  el.style.color = color || 'var(--comment)';
}

// ── Re-read handlers ──────────────────────────────────────────────────────

function sendReextract(descOnly) {
  const btn = descOnly
    ? document.getElementById('reread-desc-inline-btn')
    : document.getElementById('reread-all-btn');
  if (btn) { btn.textContent = '…'; btn.disabled = true; }

  const statusMsg = descOnly ? 'Re-reading description…' : 'Re-reading page…';
  setStatus(statusMsg, 'var(--purple)');

  chrome.runtime.sendMessage({ type: 'REEXTRACT', descOnly }, (response) => {
    if (btn) { btn.textContent = descOnly ? '↺' : '↺ Re-read page'; btn.disabled = false; }
    if (!response?.ok) {
      setStatus('Re-read failed: ' + (response?.error || 'unknown error'), 'var(--red)');
    }
    // Storage update will arrive via onChanged → populateForm / desc patch
  });
}

document.getElementById('reread-all-btn').addEventListener('click', () => sendReextract(false));
document.getElementById('reread-desc-btn').addEventListener('click', () => sendReextract(true));
document.getElementById('reread-desc-inline-btn').addEventListener('click', () => sendReextract(true));
document.getElementById('stale-reread-btn').addEventListener('click', () => sendReextract(false));

// ── Read form → submission object ─────────────────────────────────────────

function readForm() {
  const e = currentState?.extracted || {};
  return {
    title:            document.getElementById('f-title').value.trim()             || null,
    company:          document.getElementById('f-company').value.trim()           || null,
    location:         document.getElementById('f-location').value.trim()          || null,
    remote:           document.getElementById('f-remote').checked,
    employment_type:  document.getElementById('f-employment-type').value          || null,
    experience:       document.getElementById('f-experience').value.trim()        || null,
    apply_url:        document.getElementById('f-apply-url').value.trim()         || null,
    salary_min:       parseFloat(document.getElementById('f-salary-min').value)   || null,
    salary_max:       parseFloat(document.getElementById('f-salary-max').value)   || null,
    salary_currency:  document.getElementById('f-salary-currency').value          || null,
    salary_unit:      document.getElementById('f-salary-unit').value              || null,
    salary:           document.getElementById('f-salary-raw').value.trim()        || null,
    description_text: document.getElementById('f-description').value.trim()       || null,
    description_html: e.description_html || null,
    posted_at:        document.getElementById('f-posted-at').value                || null,
    valid_through:    document.getElementById('f-valid-through').value            || null,
    skills:           document.getElementById('f-skills').value.trim()            || null,
    education:        document.getElementById('f-education').value.trim()         || null,
    qualifications:   document.getElementById('f-qualifications').value.trim()    || null,
    responsibilities: document.getElementById('f-responsibilities').value.trim()  || null,
    benefits:         document.getElementById('f-benefits').value.trim()          || null,
    // Pass-through (not editable in form)
    industry:         e.industry         || null,
    company_logo_url: e.company_logo_url || null,
    _method:          e._method,
    _confidence:      e._confidence,
  };
}

// ── Submit ────────────────────────────────────────────────────────────────

document.getElementById('submit-btn').addEventListener('click', async () => {
  if (!currentState?.wwrId) {
    setStatus('No job loaded — open a job page first', 'var(--red)');
    return;
  }
  const btn = document.getElementById('submit-btn');
  btn.disabled    = true;
  btn.textContent = 'Submitting…';
  setStatus('Sending to WWWorkRemote…', 'var(--purple)');

  try {
    const result = await new Promise((resolve, reject) => {
      chrome.runtime.sendMessage(
        { type: 'SUBMIT_JOB', editedData: readForm(), wwrId: currentState.wwrId },
        (response) => {
          if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
          else resolve(response);
        }
      );
    });

    if (result?.ok) {
      btn.textContent     = '✓ Submitted';
      btn.style.background = 'var(--green)';
      setStatus(result.message || '✨ Sync complete', 'var(--green)');
    } else {
      throw new Error(result?.error || 'Unknown error from server');
    }
  } catch (err) {
    btn.disabled    = false;
    btn.textContent = 'Submit to WWWorkRemote';
    setStatus('✗ ' + err.message, 'var(--red)');
  }
});

// ── Storage listeners ─────────────────────────────────────────────────────

chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== 'session') return;
  const change = changes[SESSION_KEY];
  if (!change?.newValue) return;

  const newState = change.newValue;

  // Description-only patch: update just the description textarea
  // without clobbering the rest of the user's edits.
  if (currentState &&
      newState.extracted?.description_text !== currentState.extracted?.description_text) {
    const oldExtracted = currentState.extracted || {};
    const newExtracted = newState.extracted || {};
    const onlyDescChanged = Object.keys(newExtracted).every(k =>
      k === 'description_text' || k === 'description_html' ||
      newExtracted[k] === oldExtracted[k]
    );

    if (onlyDescChanged) {
      // Just update the description field
      const ta      = document.getElementById('f-description');
      const rawDesc = newExtracted.description_text || '';
      const clean   = rawDesc.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
      ta.value      = clean;
      currentState.extracted.description_text = newExtracted.description_text;
      currentState.extracted.description_html = newExtracted.description_html;
      markSource('src-description', !!clean);
      applyFieldState('fld-description', 'f-description');
      updateWordCount();
      setStatus('Description updated from page', 'var(--green)');
      return;
    }
  }

  // Full repopulate (new job or full re-read)
  populateForm(newState);
});

// ── Init ──────────────────────────────────────────────────────────────────

function init() {
  chrome.storage.session.get(SESSION_KEY, (data) => {
    const state = data?.[SESSION_KEY];
    if (state?.extracted) populateForm(state);
    else                  showEmpty();
  });
}

init();

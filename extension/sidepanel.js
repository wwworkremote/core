// sidepanel.js — WWWorkRemote Review Panel
//
// Reads extracted job data from chrome.storage.session (written by background.js
// when content.js fires OPEN_PANEL), populates all form fields, and submits
// user-reviewed data back through background.js → content.js → Rails API.

'use strict';

const SESSION_KEY = 'wwr_panel_state';

// ── Field definitions ─────────────────────────────────────────────────────
// Maps each form field ID to the key(s) it reads from the extracted object.
// Multiple keys = first non-empty value wins.

const FIELD_MAP = {
  'f-title':           ['title'],
  'f-company':         ['company'],
  'f-location':        ['location'],
  'f-remote':          ['remote'],
  'f-employment-type': ['employment_type'],
  'f-experience':      ['experience'],
  'f-apply-url':       ['apply_url', 'canonical_url'],
  'f-salary-min':      ['salary_min'],
  'f-salary-max':      ['salary_max'],
  'f-salary-currency': ['salary_currency'],
  'f-salary-unit':     ['salary_unit'],
  'f-salary-raw':      ['salary'],
  'f-description':     ['description_text'],
  'f-posted-at':       ['posted_at'],
  'f-valid-through':   ['valid_through'],
  'f-skills':          ['skills', 'tags'],
};

// Source badge element IDs map (field container → src dot)
const SRC_MAP = {
  'fld-title':           'src-title',
  'fld-company':         'src-company',
  'fld-location':        'src-location',
  'fld-remote':          'src-remote',
  'fld-employment-type': 'src-employment-type',
  'fld-experience':      'src-experience',
  'fld-apply-url':       'src-apply-url',
  'fld-salary-range':    'src-salary',
  'fld-description':     'src-description',
  'fld-posted-at':       'src-posted-at',
  'fld-valid-through':   'src-valid-through',
  'fld-skills':          'src-skills',
};

// Required fields — get yellow accent if empty
const REQUIRED = new Set(['f-title']);

// ── Helpers ───────────────────────────────────────────────────────────────

function coalesce(extracted, ...keys) {
  for (const k of keys) {
    const v = extracted[k];
    if (v !== null && v !== undefined && v !== '') return v;
  }
  return null;
}

function toDateInput(val) {
  if (!val) return '';
  // Accept ISO 8601 date strings and timestamps
  try {
    const d = new Date(val);
    if (isNaN(d.getTime())) return '';
    return d.toISOString().slice(0, 10); // YYYY-MM-DD
  } catch (_) { return ''; }
}

function normalizeEmploymentType(val) {
  if (!val) return '';
  const map = {
    'full-time': 'FULL_TIME', 'full_time': 'FULL_TIME', 'fulltime': 'FULL_TIME',
    'part-time': 'PART_TIME', 'part_time': 'PART_TIME', 'parttime': 'PART_TIME',
    'contract':  'CONTRACTOR', 'contractor': 'CONTRACTOR', 'freelance': 'CONTRACTOR',
    'temporary': 'TEMPORARY', 'temp': 'TEMPORARY',
    'intern':    'INTERN', 'internship': 'INTERN',
    'volunteer': 'VOLUNTEER',
    'other':     'OTHER',
  };
  return map[val.toLowerCase().replace(/\s+/g, '-')] || val.toUpperCase();
}

function tagsToString(val) {
  if (Array.isArray(val)) return val.join(', ');
  if (typeof val === 'string') return val;
  return '';
}

function wordCount(str) {
  return str ? str.trim().split(/\s+/).filter(Boolean).length : 0;
}

// ── Show / hide app sections ──────────────────────────────────────────────

function showPanel() {
  document.getElementById('empty-state').style.display  = 'none';
  document.getElementById('header').style.display       = '';
  document.getElementById('form-body').style.display    = '';
  document.getElementById('footer').style.display       = '';
}

function showEmpty() {
  document.getElementById('empty-state').style.display  = 'flex';
  document.getElementById('header').style.display       = 'none';
  document.getElementById('form-body').style.display    = 'none';
  document.getElementById('footer').style.display       = 'none';
}

// ── Confidence badge ──────────────────────────────────────────────────────

const CONFIDENCE_STYLES = {
  json_ld: { label: 'JSON-LD ✓', color: '#282a36', bg: '#50fa7b' },
  css:     { label: 'CSS ◎',     color: '#282a36', bg: '#f1fa8c' },
  meta:    { label: 'Meta ◎',    color: '#282a36', bg: '#ffb86c' },
  generic: { label: 'Generic ⚠', color: '#f8f8f2', bg: '#ff5555' },
};

function updateConfidenceBadge(method) {
  const el = document.getElementById('confidence-badge');
  if (!el) return;
  const s = CONFIDENCE_STYLES[method] || CONFIDENCE_STYLES.generic;
  el.textContent = s.label;
  el.style.color      = s.color;
  el.style.background = s.bg;
  el.style.padding    = '1px 7px';
  el.style.borderRadius = '3px';
}

// ── Populate form ─────────────────────────────────────────────────────────

let currentState = null;

function populateForm(state) {
  currentState = state;
  const e = state.extracted || {};

  showPanel();

  // Header meta
  document.getElementById('hdr-id').textContent    = state.wwrId || '—';
  document.getElementById('hdr-board').textContent = formatBoard(state.provider);
  updateConfidenceBadge(e._method);

  // ── Title ────────────────────────────────────────────────────────────────
  setValue('f-title',   coalesce(e, 'title'),   'fld-title',   'src-title');

  // ── Company ──────────────────────────────────────────────────────────────
  setValue('f-company', coalesce(e, 'company'), 'fld-company', 'src-company');

  // ── Location ─────────────────────────────────────────────────────────────
  setValue('f-location', coalesce(e, 'location'), 'fld-location', 'src-location');

  // ── Remote ───────────────────────────────────────────────────────────────
  const remoteVal = coalesce(e, 'remote');
  const remoteEl  = document.getElementById('f-remote');
  const remoteChecked = remoteVal === true || remoteVal === 'true' ||
    (typeof remoteVal === 'string' && remoteVal.toLowerCase().includes('telecommute'));
  remoteEl.checked = remoteChecked;
  markSource('fld-remote', 'src-remote', remoteVal !== null && remoteVal !== undefined);
  document.getElementById('remote-label').textContent = remoteChecked ? '✓ Remote position' : 'Remote position';
  document.getElementById('fld-remote').classList.toggle('filled', remoteChecked);
  document.getElementById('fld-remote').classList.toggle('empty',  !remoteChecked);

  // ── Employment type ───────────────────────────────────────────────────────
  const rawType = coalesce(e, 'employment_type');
  const normType = normalizeEmploymentType(rawType || '');
  const sel = document.getElementById('f-employment-type');
  const matched = [...sel.options].some(o => o.value === normType);
  sel.value = matched ? normType : '';
  if (!matched && rawType) {
    // Add as custom option if not in list
    const opt = new Option(rawType, rawType);
    sel.add(opt);
    sel.value = rawType;
  }
  markSource('fld-employment-type', 'src-employment-type', !!rawType);
  applyFieldState('fld-employment-type', 'f-employment-type', false);

  // ── Experience ────────────────────────────────────────────────────────────
  const expVal = coalesce(e, 'experience');
  setValue('f-experience', typeof expVal === 'string' ? expVal : null, 'fld-experience', 'src-experience');

  // ── Apply URL ─────────────────────────────────────────────────────────────
  const applyUrl = coalesce(e, 'apply_url', 'canonical_url');
  setValue('f-apply-url', applyUrl, 'fld-apply-url', 'src-apply-url');
  const applyLink = document.getElementById('apply-link');
  if (applyUrl) {
    applyLink.href = applyUrl;
    applyLink.style.display = 'block';
  } else {
    applyLink.style.display = 'none';
  }

  // ── Salary (structured) ───────────────────────────────────────────────────
  const hasStructuredSalary = !!(coalesce(e, 'salary_min') || coalesce(e, 'salary_max') || coalesce(e, 'salary_value'));
  setValue('f-salary-min', coalesce(e, 'salary_min'), null, null);
  setValue('f-salary-max', coalesce(e, 'salary_max'), null, null);

  // Currency select
  const cur = coalesce(e, 'salary_currency') || '';
  const curSel = document.getElementById('f-salary-currency');
  const curMatched = [...curSel.options].some(o => o.value === cur);
  curSel.value = curMatched ? cur : '';
  if (!curMatched && cur) {
    curSel.add(new Option(cur, cur));
    curSel.value = cur;
  }

  // Unit select
  const unit = coalesce(e, 'salary_unit') || '';
  const unitSel = document.getElementById('f-salary-unit');
  const unitNorm = unit.toUpperCase().replace('YEAR', 'YEAR').replace('ANNUAL', 'YEAR')
    .replace('MONTHLY', 'MONTH').replace('HOURLY', 'HOUR');
  unitSel.value = ['YEAR','MONTH','HOUR'].includes(unitNorm) ? unitNorm : '';

  // Raw salary fallback
  const rawSalary = coalesce(e, 'salary');
  setValue('f-salary-raw', hasStructuredSalary ? null : rawSalary, null, null);

  const hasSalaryAny = hasStructuredSalary || !!rawSalary;
  markSource('fld-salary-range', 'src-salary', hasSalaryAny);
  applyFieldState('fld-salary-range', 'f-salary-min', false);

  // ── Description ───────────────────────────────────────────────────────────
  const desc = coalesce(e, 'description_text', 'description_html');
  const cleanDesc = desc ? desc.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim() : '';
  setValue('f-description', cleanDesc || null, 'fld-description', 'src-description');
  updateWordCount();

  // ── Posted at / Valid through ─────────────────────────────────────────────
  const postedAt = toDateInput(coalesce(e, 'posted_at'));
  document.getElementById('f-posted-at').value = postedAt;
  markSource('fld-posted-at', 'src-posted-at', !!postedAt);
  applyFieldState('fld-posted-at', 'f-posted-at', false);

  const validThrough = toDateInput(coalesce(e, 'valid_through'));
  document.getElementById('f-valid-through').value = validThrough;
  markSource('fld-valid-through', 'src-valid-through', !!validThrough);
  applyFieldState('fld-valid-through', 'f-valid-through', false);

  // ── Skills / Tags ─────────────────────────────────────────────────────────
  const skillsVal = coalesce(e, 'skills', 'tags');
  setValue('f-skills', tagsToString(skillsVal) || null, 'fld-skills', 'src-skills');

  // ── Summary counts ────────────────────────────────────────────────────────
  const total   = Object.keys(FIELD_MAP).length;
  const filled  = countFilledFields();
  const missing = total - filled;
  document.getElementById('hdr-filled').textContent  = filled;
  document.getElementById('hdr-missing').textContent = missing > 0
    ? `${missing} to fill in` : 'all fields extracted';
  document.getElementById('hdr-missing').style.color = missing > 0
    ? 'var(--yellow)' : 'var(--green)';

  // Enable submit
  document.getElementById('submit-btn').disabled = false;
  setStatus('Ready — review fields and submit');
}

// ── Set value + mark source dot ───────────────────────────────────────────

function setValue(inputId, value, fieldId, srcId) {
  const el = document.getElementById(inputId);
  if (!el) return;
  const hasValue = value !== null && value !== undefined && value !== '';
  el.value = hasValue ? String(value) : '';
  if (srcId) markSource(fieldId, srcId, hasValue);
  if (fieldId) applyFieldState(fieldId, inputId, REQUIRED.has(inputId));
}

function markSource(fieldId, srcId, found) {
  const dot = document.getElementById(srcId);
  if (!dot) return;
  dot.classList.toggle('found',   found);
  dot.classList.toggle('missing', !found);
  dot.title = found ? 'Extracted from page' : 'Not found — enter manually';
}

function applyFieldState(fieldId, inputId, isRequired) {
  const field  = document.getElementById(fieldId);
  const input  = document.getElementById(inputId);
  if (!field || !input) return;
  const hasVal = (input.type === 'checkbox' ? input.checked : input.value.trim()) !== (input.type === 'checkbox' ? false : '');
  field.classList.remove('filled', 'empty', 'empty-required');
  if (hasVal) {
    field.classList.add('filled');
  } else if (isRequired) {
    field.classList.add('empty-required');
  } else {
    field.classList.add('empty');
  }
}

// ── Word count ────────────────────────────────────────────────────────────

function updateWordCount() {
  const ta = document.getElementById('f-description');
  const wc = wordCount(ta?.value || '');
  const el = document.getElementById('desc-meta');
  if (!el) return;
  el.textContent = `${wc} words`;
  el.style.color = wc > 200 ? 'var(--green)' : wc > 50 ? 'var(--yellow)' : 'var(--red)';
}

// ── Count filled fields ────────────────────────────────────────────────────

function countFilledFields() {
  let n = 0;
  for (const id of Object.keys(FIELD_MAP)) {
    const el = document.getElementById(id);
    if (!el) continue;
    if (el.type === 'checkbox') { if (el.checked) n++; }
    else if (el.value?.trim()) n++;
  }
  return n;
}

// ── Board label ───────────────────────────────────────────────────────────

function formatBoard(provider) {
  const labels = {
    linkedin: 'LinkedIn', indeed: 'Indeed', adzuna: 'Adzuna',
    weworkremotely: 'WeWorkRemotely', remoteok: 'RemoteOK',
    greenhouse: 'Greenhouse', lever: 'Lever', workday: 'Workday',
    ashby: 'Ashby', smartrecruiters: 'SmartRecruiters', wellfound: 'Wellfound',
    generic: 'Generic',
  };
  return labels[provider] || provider || '—';
}

// ── Status line ────────────────────────────────────────────────────────────

function setStatus(msg, color) {
  const el = document.getElementById('status-line');
  if (!el) return;
  el.textContent    = msg;
  el.style.color    = color || 'var(--comment)';
}

// ── Read form into submission object ──────────────────────────────────────

function readForm() {
  const e = currentState?.extracted || {};
  return {
    title:            document.getElementById('f-title').value.trim()           || null,
    company:          document.getElementById('f-company').value.trim()         || null,
    location:         document.getElementById('f-location').value.trim()        || null,
    remote:           document.getElementById('f-remote').checked,
    employment_type:  document.getElementById('f-employment-type').value        || null,
    experience:       document.getElementById('f-experience').value.trim()      || null,
    apply_url:        document.getElementById('f-apply-url').value.trim()       || null,
    salary_min:       parseFloat(document.getElementById('f-salary-min').value) || null,
    salary_max:       parseFloat(document.getElementById('f-salary-max').value) || null,
    salary_currency:  document.getElementById('f-salary-currency').value        || null,
    salary_unit:      document.getElementById('f-salary-unit').value            || null,
    salary:           document.getElementById('f-salary-raw').value.trim()      || null,
    description_text: document.getElementById('f-description').value.trim()     || null,
    description_html: e.description_html || null,  // preserve original HTML for backend
    posted_at:        document.getElementById('f-posted-at').value              || null,
    valid_through:    document.getElementById('f-valid-through').value          || null,
    skills:           document.getElementById('f-skills').value.trim()          || null,
    // Pass-through fields not in the form
    industry:         e.industry         || null,
    qualifications:   e.qualifications   || null,
    responsibilities: e.responsibilities || null,
    benefits:         e.benefits         || null,
    education:        e.education        || null,
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
  btn.disabled   = true;
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
      btn.textContent      = '✓ Submitted';
      btn.style.background = 'var(--green)';
      setStatus(result.message || '✨ Sync complete', 'var(--green)');
    } else {
      throw new Error(result?.error || 'Unknown error from server');
    }
  } catch (err) {
    btn.disabled   = false;
    btn.textContent = 'Submit to WWWorkRemote';
    setStatus('✗ ' + err.message, 'var(--red)');
  }
});

// ── Real-time word count ──────────────────────────────────────────────────

document.getElementById('f-description').addEventListener('input', updateWordCount);

// Apply URL → update open link
document.getElementById('f-apply-url').addEventListener('input', function () {
  const link = document.getElementById('apply-link');
  if (this.value.trim()) {
    link.href = this.value.trim();
    link.style.display = 'block';
  } else {
    link.style.display = 'none';
  }
});

// Remote checkbox → update label
document.getElementById('f-remote').addEventListener('change', function () {
  document.getElementById('remote-label').textContent =
    this.checked ? '✓ Remote position' : 'Remote position';
});

// ── Init: load from storage ────────────────────────────────────────────────

function init() {
  chrome.storage.session.get(SESSION_KEY, (data) => {
    const state = data?.[SESSION_KEY];
    if (state?.extracted) {
      populateForm(state);
    } else {
      showEmpty();
    }
  });
}

// Re-populate when a new job is opened in the tab (storage changes)
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== 'session') return;
  const change = changes[SESSION_KEY];
  if (!change) return;
  const state = change.newValue;
  if (state?.extracted) {
    // Reset submit button state on new job
    const btn = document.getElementById('submit-btn');
    btn.disabled        = false;
    btn.textContent     = 'Submit to WWWorkRemote';
    btn.style.background = '';
    populateForm(state);
  }
});

init();

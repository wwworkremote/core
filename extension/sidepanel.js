// sidepanel.js — WWWorkRemote Review Panel
'use strict';

const SESSION_KEY = 'wwr_panel_state';
const DEFAULT_API = 'http://localhost:31000';

// ── API config (mirrors content.js's getApiConfig) ──────────────────────────
// Side panels are extension pages with their own host-permission access, so
// this fetches directly rather than relaying through the content script.

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

function escapeHtml(str) {
  return String(str ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function debounce(fn, ms) {
  let timer = null;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

// apply_url comes from scraped-page JSON-LD (or a user edit of that value) --
// reject javascript:/data: schemes before ever assigning it to an href.
function safeHttpUrl(url) {
  try {
    const u = new URL(url);
    return (u.protocol === 'http:' || u.protocol === 'https:') ? url : null;
  } catch {
    return null;
  }
}

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
  json_ld: { label: 'JSON-LD ✓', color: '#22212c', bg: '#8aff80' },
  css:     { label: 'CSS ◎',     color: '#22212c', bg: '#ffff80' },
  meta:    { label: 'Meta ◎',    color: '#22212c', bg: '#ffca80' },
  generic: { label: 'Generic ⚠', color: '#f8f8f2', bg: '#ff9580' },
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

// ── Company match picker (capture mode only) ────────────────────────────────

let selectedCompanyId = null;

async function searchCompanyMatches(query) {
  const container = document.getElementById('company-matches');
  if (!container) return;
  if (!query) { container.style.display = 'none'; container.innerHTML = ''; return; }

  container.style.display = 'block';
  container.innerHTML = '<div class="company-match-loading">Searching companies…</div>';

  try {
    const { base: apiBase, authHeader } = await getApiConfig();
    const headers = {};
    if (authHeader) headers['Authorization'] = authHeader;
    const response = await fetch(`${apiBase}/api/companies/search?q=${encodeURIComponent(query)}`, { headers });
    const matches = response.ok ? await response.json() : [];
    renderCompanyMatches(matches, query);
  } catch (_) {
    container.style.display = 'none';
    container.innerHTML = '';
  }
}

function renderCompanyMatches(matches, query) {
  const container = document.getElementById('company-matches');
  if (!container) return;
  selectedCompanyId = null;

  const items = matches.map(m =>
    `<button type="button" class="company-match-option" data-id="${m.id}" data-name="${escapeHtml(m.name)}">${escapeHtml(m.name)}</button>`
  ).join('');

  container.innerHTML = `
    <div class="company-match-label">Existing companies</div>
    ${items || '<div class="company-match-empty">No matches</div>'}
    <button type="button" class="company-match-create" data-name="${escapeHtml(query)}">+ Create new: "${escapeHtml(query)}"</button>
  `;
  container.style.display = 'block';

  container.querySelectorAll('.company-match-option').forEach(btn => {
    btn.addEventListener('click', () => {
      selectedCompanyId = btn.dataset.id;
      document.getElementById('f-company').value = btn.dataset.name;
      highlightSelectedCompany(btn);
    });
  });

  const createBtn = container.querySelector('.company-match-create');
  if (createBtn) {
    createBtn.addEventListener('click', () => {
      selectedCompanyId = null;
      highlightSelectedCompany(createBtn);
    });
  }
}

// ── Application Q&A (TASK-78) ───────────────────────────────────────────────
// Read-only: matches screening questions found on a Greenhouse application
// page against this job's existing ApplicationQuestion answers. Copy-paste
// only -- never writes into the page's form fields. Unmatched questions get
// a "Generate answer" action that round-trips to the AI-answer endpoint.
function copyButtonHtml(idx) {
  return `<button type="button" class="qa-copy-btn" data-idx="${idx}">Copy answer</button>`;
}

function attachCopyHandlers(container, getAnswer) {
  container.querySelectorAll('.qa-copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      navigator.clipboard.writeText(getAnswer(Number(btn.dataset.idx))).then(() => {
        btn.textContent = 'Copied ✓';
        btn.classList.add('copied');
        setTimeout(() => { btn.textContent = 'Copy answer'; btn.classList.remove('copied'); }, 1500);
      });
    });
  });
}

function renderApplicationQA(qa) {
  const container = document.getElementById('application-qa-section');
  if (!container) return;

  const matches = qa?.matches || [];
  const unmatched = qa?.unmatched || [];
  if (!matches.length && !unmatched.length) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  const matchItems = matches.map((m, i) => `
    <div class="qa-item">
      <div class="qa-question">${escapeHtml(m.question)}</div>
      <div class="qa-answer">${escapeHtml(m.answer)}</div>
      ${copyButtonHtml(i)}
    </div>
  `).join('');

  const unmatchedItems = unmatched.map((q, i) => `
    <div class="qa-item">
      <div class="qa-question">${escapeHtml(q)}</div>
      <div class="qa-answer qa-unanswered">No saved answer yet</div>
      <button type="button" class="qa-generate-btn" data-idx="${i}">✨ Generate answer</button>
    </div>
  `).join('');

  const headerParts = [];
  if (matches.length) headerParts.push(`${matches.length} match${matches.length === 1 ? '' : 'es'}`);
  if (unmatched.length) headerParts.push(`${unmatched.length} new`);

  container.innerHTML =
    `<div class="qa-header">Application Q&amp;A — ${headerParts.join(', ')}</div>${matchItems}${unmatchedItems}`;
  container.style.display = 'block';

  attachCopyHandlers(container, i => matches[i].answer);

  container.querySelectorAll('.qa-generate-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const questionText = unmatched[Number(btn.dataset.idx)];
      btn.disabled = true;
      btn.textContent = 'Generating…';
      chrome.runtime.sendMessage({ type: 'GENERATE_ANSWER', questionText }, (response) => {
        if (!response?.ok) {
          btn.disabled = false;
          btn.textContent = `⚠ ${response?.error || 'Failed'} — retry`;
          return;
        }
        const item = btn.closest('.qa-item');
        item.querySelector('.qa-answer').textContent = response.answer;
        item.querySelector('.qa-answer').classList.remove('qa-unanswered');
        btn.outerHTML = copyButtonHtml(`gen-${btn.dataset.idx}`);
        attachCopyHandlers(item, () => response.answer);
      });
    });
  });
}

// ── Profile fields (TASK-78) ────────────────────────────────────────────────
// Copy-paste suggestions for the personal-info fields every ATS application
// asks for (name/email/phone/links/location), sourced from CareerProfile.
// Ordered the way a form asks for them -- identity, contact, address, links
// -- so copying down a form is a walk down this list. City/State/Country are
// separate rows because plenty of ATS forms split the address instead of
// taking `location`'s combined string.
const PROFILE_FIELD_LABELS = [
  ['first_name', 'Legal first name'], ['middle_name', 'Legal middle name'],
  ['last_name', 'Legal last name'], ['preferred_name', 'Preferred first name'],
  ['name', 'Display name'], ['email', 'Email'], ['phone', 'Phone'],
  ['address_line1', 'Address line 1'], ['postal_code', 'Postal code'],
  ['phone_country_code', 'Country phone code'], ['phone_area_code', 'Area code'],
  ['phone_number', 'Phone number'],
  ['location', 'Location'], ['city', 'City'], ['state', 'State'], ['country', 'Country'],
  ['linkedin_url', 'LinkedIn'], ['github_url', 'GitHub'], ['website_url', 'Website'],
];

function renderProfileFields(profile) {
  const container = document.getElementById('profile-fields-section');
  if (!container) return;

  const present = PROFILE_FIELD_LABELS.filter(([key]) => profile?.[key]);
  if (!present.length && !profile) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  const items = present.map(([key, label], i) => `
    <div class="qa-item">
      <div class="qa-question">${escapeHtml(label)}</div>
      <div class="qa-answer">${escapeHtml(profile[key])}</div>
      ${copyButtonHtml(i)}
    </div>
  `).join('');

  const editFields = PROFILE_FIELD_LABELS.slice(0, 14);
  const editor = `<button type="button" id="edit-profile-fields-btn" class="app-map-btn">Edit key fields</button>
    <div id="profile-edit-form" style="display:none">${editFields.map(([key, label]) =>
      `<label class="profile-edit-label">${escapeHtml(label)}<input data-profile-key="${key}" value="${escapeHtml(profile?.[key] || '')}"></label>`
    ).join('')}<button type="button" id="save-profile-fields-btn" class="app-fill-btn">Save key fields</button></div>`;
  container.innerHTML = `<div class="qa-header">Your Info — copy into the form ${editor}</div>${items}`;
  container.style.display = 'block';
  attachCopyHandlers(container, i => profile[present[i][0]]);
  document.getElementById('edit-profile-fields-btn').addEventListener('click', () => {
    const form = document.getElementById('profile-edit-form');
    form.style.display = form.style.display === 'none' ? 'block' : 'none';
  });
  document.getElementById('save-profile-fields-btn').addEventListener('click', saveProfileFields);
}

async function saveProfileFields() {
  const button = document.getElementById('save-profile-fields-btn');
  const profile = Object.fromEntries([...document.querySelectorAll('[data-profile-key]')]
    .map(input => [input.dataset.profileKey, input.value.trim()]));
  button.disabled = true; button.textContent = 'Saving…';
  try {
    const { base: apiBase, authHeader } = await getApiConfig();
    const headers = { 'Content-Type': 'application/json', ...(authHeader ? { Authorization: authHeader } : {}) };
    const response = await fetch(`${apiBase}/api/v0/profile`, { method: 'PATCH', headers, body: JSON.stringify({ profile }) });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`);
    currentState.profileFields = data;
    if (currentState.applicationContext) currentState.applicationContext.profile = data;
    chrome.storage.session.set({ [SESSION_KEY]: currentState });
    renderProfileFields(data);
    renderApplicationContext(currentState.applicationContext, currentState.applicationFields || []);
    setStatus('Key profile fields saved to WWWorkRemote', 'var(--green)');
  } catch (error) {
    setStatus(`Profile save failed: ${error.message}`, 'var(--red)');
  } finally {
    button.disabled = false; button.textContent = 'Save key fields';
  }
}

// ── Application form assist ────────────────────────────────────────────────
// Workday fields are discovered in the live page and keyed only for the
// current document. Nothing is filled until the user clicks the row's button.
function personaSuggestion(field, context, occurrence) {
  const label = field.label.toLowerCase();
  const profile = context?.profile || {};
  const normalized = label.replace(/[^a-z0-9]+/g, ' ').trim();
  const templates = (context?.answer_templates || []).filter(template =>
    template.normalized_prompt === normalized &&
    (!template.persona_id || template.persona_id === context?.selected_persona_id));
  if (templates.length) return { value: templates[0].answer, source: 'template' };
  const profileMap = [
    ['email', 'email'], ['phone', 'phone'], ['mobile', 'phone'], ['linkedin', 'linkedin_url'],
    ['github', 'github_url'], ['website', 'website_url'], ['city', 'city'],
    ['state', 'state'], ['country', 'country'], ['location', 'location'],
    ['preferred name', 'preferred_name'], ['first name', 'first_name'],
    ['middle name', 'middle_name'], ['last name', 'last_name'], ['name', 'name'],
  ];
  const profileKey = profileMap.find(([needle]) => label.includes(needle))?.[1];
  if (profileKey && profile[profileKey]) return { value: profile[profileKey], source: 'profile' };

  const positions = context?.persona?.positions || [];
  const index = occurrence[label] || 0;
  if (/job title|title|role/.test(label)) return { value: positions[index]?.title || '', source: 'manual' };
  if (/company|employer/.test(label)) return { value: positions[index]?.company?.name || '', source: 'manual' };
  if (/description|responsibilit|duties|summary/.test(label)) return { value: positions[index]?.summary || '', source: 'manual' };
  if (/start/.test(label)) return { value: positions[index]?.start_date || '', source: 'manual' };
  if (/end|finish/.test(label)) return { value: positions[index]?.end_date || '', source: 'manual' };
  return { value: '', source: 'manual' };
}

function semanticSuggestion(field) {
  const label = field.label.toLowerCase();
  const profileMap = [
    ['email', 'profile.email', 'Personal email'], ['phone', 'profile.phone', 'Personal phone'],
    ['mobile', 'profile.phone', 'Personal phone'], ['preferred name', 'profile.preferred_name', 'Preferred first name'],
    ['first name', 'profile.first_name', 'Legal first name'], ['middle name', 'profile.middle_name', 'Legal middle name'],
    ['last name', 'profile.last_name', 'Legal last name'], ['linkedin', 'profile.linkedin_url', 'LinkedIn URL'],
    ['github', 'profile.github_url', 'GitHub URL'], ['city', 'profile.city', 'City'],
    ['state', 'profile.state', 'State'], ['country', 'profile.country', 'Country'],
  ];
  const match = profileMap.find(([needle]) => label.includes(needle));
  if (match) return { key: match[1], label: match[2], kind: 'profile' };
  if (/job title|title|role/.test(label)) return { key: 'persona.positions[].title', label: 'Persona work history title', kind: 'persona' };
  if (/company|employer/.test(label)) return { key: 'persona.positions[].company', label: 'Persona work history company', kind: 'persona' };
  if (/question|why|interest|authorization|sponsor/.test(label)) return { key: 'application.question', label: 'Application question answer', kind: 'question' };
  return { key: '', label: '', kind: 'manual' };
}

async function selectApplicationPersona(personaId) {
  const { base: apiBase, authHeader } = await getApiConfig();
  const headers = { 'Content-Type': 'application/json', ...(authHeader ? { Authorization: authHeader } : {}) };
  const response = await fetch(`${apiBase}/api/v0/job_postings/${currentState.wwrId}/application_context`, {
    method: 'PATCH', headers, body: JSON.stringify({ persona_id: personaId }),
  });
  const data = await response.json();
  if (!response.ok || !data.selected_persona_id) throw new Error(data.error || `HTTP ${response.status}`);
  currentState.applicationContext = data;
  currentState.profileFields = data.profile;
  chrome.storage.session.set({ [SESSION_KEY]: currentState });
  renderApplicationContext(data, currentState.applicationFields || []);
  renderProfileFields(data.profile);
}

function renderApplicationContext(context, fields) {
  const container = document.getElementById('application-context-section');
  if (!container || !context) {
    if (container) { container.style.display = 'none'; container.innerHTML = ''; }
    return;
  }

  const occurrence = {};
  const rows = (fields || []).map((field) => {
    const normalized = field.label.toLowerCase();
    const suggestion = personaSuggestion(field, context, occurrence);
    occurrence[normalized] = (occurrence[normalized] || 0) + 1;
    const saved = (context.field_answers || []).find(answer => answer.field_key === field.key);
    const mapping = (context.mappings || []).find(item => item.field_key === field.key);
    const value = saved?.answer || suggestion.value || field.currentValue || '';
    const source = saved?.answer_source || suggestion.source;
    return `<div class="app-field-row" data-field-key="${escapeHtml(field.key)}">
      <div class="app-field-label"><span>${escapeHtml(field.label)}</span>${field.required ? '<b>*</b>' : ''}</div>
      <textarea class="app-field-answer" rows="2">${escapeHtml(value)}</textarea>
      <div class="app-field-actions"><span class="app-field-source">${mapping ? `mapped → ${escapeHtml(mapping.semantic_key)}` : (saved ? 'provided' : source)}</span>
        <button type="button" class="app-map-btn">${mapping ? 'Remap' : 'Map'}</button>
        <button type="button" class="app-fill-btn" data-source="${escapeHtml(source)}">Fill</button></div>
    </div>`;
  }).join('');

  const personaOptions = (context.personas || []).map(persona =>
    `<option value="${escapeHtml(persona.id)}" ${persona.id === context.selected_persona_id ? 'selected' : ''}>${escapeHtml(persona.label || persona.title || persona.id)}</option>`
  ).join('');
  const summary = context.question_summary || {};
  const summaryText = Object.entries(summary).map(([kind, count]) => `${kind}: ${count}`).join(' · ');
  container.innerHTML = `<div class="qa-header">Application cockpit — ${(fields || []).length} visible fields${summaryText ? ` · observed ${escapeHtml(summaryText)}` : ''}
    <button type="button" id="refresh-application-fields" class="app-map-btn">↻ Refresh fields</button></div>
    <div class="persona-picker"><label for="application-persona">Resume persona</label>
      <select id="application-persona">${personaOptions}</select>
      <button type="button" id="save-persona-btn">Use persona</button></div>${rows}`;
  container.style.display = 'block';

  document.getElementById('refresh-application-fields').addEventListener('click', () => {
    chrome.runtime.sendMessage({ type: 'REFRESH_APPLICATION_FIELDS' });
    setStatus('Refreshing visible application fields…', 'var(--purple)');
  });

  document.getElementById('save-persona-btn').addEventListener('click', async () => {
    const btn = document.getElementById('save-persona-btn');
    btn.disabled = true; btn.textContent = 'Saving…';
    try { await selectApplicationPersona(document.getElementById('application-persona').value); setStatus('Persona locked to this application', 'var(--green)'); }
    catch (err) { setStatus(`Persona save failed: ${err.message}`, 'var(--red)'); }
    finally { btn.disabled = false; btn.textContent = 'Use persona'; }
  });

  container.querySelectorAll('.app-fill-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const row = btn.closest('.app-field-row');
      const fieldKey = row.dataset.fieldKey;
      const value = row.querySelector('.app-field-answer').value.trim();
      if (!value) { setStatus('Enter an answer before filling', 'var(--yellow)'); return; }
      btn.disabled = true; btn.textContent = 'Filling…';
      chrome.runtime.sendMessage({ type: 'FILL_APPLICATION_FIELD', fieldKey, value, source: btn.dataset.source }, response => {
        btn.disabled = false;
        if (!response?.ok) { btn.textContent = 'Retry'; setStatus(`Fill failed: ${response?.error || 'unknown error'}`, 'var(--red)'); return; }
        btn.textContent = 'Filled ✓';
        row.querySelector('.app-field-source').textContent = 'provided';
        setStatus(`${response.field.label} provided and tracked`, 'var(--green)');
        setTimeout(() => { btn.textContent = 'Fill'; }, 1500);
      });
    });
  });

  container.querySelectorAll('.app-map-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const row = btn.closest('.app-field-row');
      btn.disabled = true;
      btn.textContent = 'Click field…';
      startApplicationMapping(row.dataset.fieldKey, btn);
    });
  });
}

async function recordApplicationFieldObservations(state) {
  if (!state?.wwrId || !state.applicationFields?.length) return;
  const { base: apiBase, authHeader } = await getApiConfig();
  const headers = { 'Content-Type': 'application/json', ...(authHeader ? { Authorization: authHeader } : {}) };
  await fetch(`${apiBase}/api/v0/job_postings/${state.wwrId}/application_field_observations`, {
    method: 'POST', headers,
    body: JSON.stringify({ observations: state.applicationFields.map(field => ({
      field_key: field.key, field_label: field.label, field_type: field.type,
      page_url: state.pageUrl, context: { required: field.required, current_value: !!field.currentValue },
    })) }),
  });
}

// ── Application lifecycle (TASK-78) ─────────────────────────────────────────
// The panel is open on the ATS page at the exact moment the user applies, so
// this is where the status transition belongs -- previously the only control
// lived in the web app and `applied` was effectively never recorded.
const STATUS_EVENT_LABELS = {
  favorite: '♥ Favorite', apply: '✓ Mark Applied', interview: '◎ Interviewing',
  offer: '★ Offered', archive: '⨯ Archive',
};

function renderApplicationStatus(status) {
  const container = document.getElementById('application-status-section');
  if (!container) return;

  if (!status) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  const buttons = (status.available_events || [])
    .map(ev => `<button type="button" class="status-btn" data-event="${escapeHtml(ev)}">${STATUS_EVENT_LABELS[ev] || ev}</button>`)
    .join('');

  // The captured count is the only feedback that the answers on the page went
  // with the transition -- without it the user can't tell a status-only click
  // from one that also banked the Q&A for next time.
  const captured = Number(status.captured) > 0
    ? ` · captured ${status.captured} answer${status.captured === 1 ? '' : 's'}`
    : '';

  container.innerHTML =
    `<div class="qa-header">Application Status — ${escapeHtml(status.status || 'none')}${captured}</div>
     <div class="status-actions">${buttons}</div>`;
  container.style.display = 'block';

  container.querySelectorAll('.status-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const event = btn.dataset.event;
      container.querySelectorAll('.status-btn').forEach(b => { b.disabled = true; });
      btn.textContent = 'Saving…';
      chrome.runtime.sendMessage({ type: 'SET_APPLICATION_STATUS', event }, (response) => {
        if (!response?.ok) {
          container.querySelectorAll('.status-btn').forEach(b => { b.disabled = false; });
          btn.textContent = `⚠ ${response?.error || 'Failed'} — retry`;
          return;
        }
        renderApplicationStatus({
          status: response.status,
          available_events: response.availableEvents,
          captured: response.captured,
        });
      });
    });
  });
}

function renderApplicationCompletion(completion) {
  const container = document.getElementById('application-completion-section');
  if (!container) return;
  if (!completion) { container.style.display = 'none'; container.innerHTML = ''; return; }
  const linked = currentState?.wwrId;
  container.innerHTML = `
    <div class="qa-header">Workday completion detected</div>
    <div class="qa-answer">${escapeHtml((completion.evidence || []).join(' · '))}</div>
    <div class="qa-answer">${linked ? `Tracked application #${escapeHtml(linked)} — ${escapeHtml(completion.title || '')}` : 'No tracked WWWorkRemote posting was carried across this tab.'}</div>
    ${linked ? '<button type="button" class="status-btn" id="completion-mark-applied">Mark applied + save evidence</button>' : '<div class="qa-answer qa-unanswered">Open the tracked application link before submitting to preserve the association.</div>'}`;
  container.style.display = 'block';
  const btn = document.getElementById('completion-mark-applied');
  if (!btn) return;
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    btn.textContent = 'Saving…';
    try {
      const { base: apiBase, authHeader } = await getApiConfig();
      const headers = { 'Content-Type': 'application/json', ...(authHeader ? { Authorization: authHeader } : {}) };
      const response = await fetch(`${apiBase}/api/v0/job_postings/${currentState.wwrId}/application_status`, {
        method: 'POST', headers,
        body: JSON.stringify({ event: 'apply', link: completion.pageUrl }),
      });
      const data = await response.json();
      if (!response.ok || !data.success) throw new Error(data.error || `HTTP ${response.status}`);
      currentState.applicationStatus = data;
      renderApplicationStatus(data);
      btn.textContent = '✓ Applied + evidence saved';
      setStatus('Application marked applied', 'var(--green)');
    } catch (err) {
      btn.disabled = false;
      btn.textContent = 'Mark applied + save evidence';
      setStatus('✗ ' + err.message, 'var(--red)');
    }
  });
}

function highlightSelectedCompany(selectedEl) {
  document.querySelectorAll('.company-match-option, .company-match-create')
    .forEach(el => el.classList.remove('selected'));
  selectedEl.classList.add('selected');
}

const debouncedCompanySearch = debounce(query => searchCompanyMatches(query), 400);

document.getElementById('f-company').addEventListener('input', function () {
  if (currentState?.mode === 'capture') debouncedCompanySearch(this.value.trim());
});

// ── Main populate ─────────────────────────────────────────────────────────

let currentState = null;

function populateForm(state) {
  currentState = state;
  const e = state.extracted || {};
  const mode = state.mode || 'enrich'; // older stored sessions predate `mode` — treat as enrich

  showPanel();

  // Staleness banner
  const banner = document.getElementById('stale-banner');
  if (state.stale) {
    banner.style.display = 'flex';
  } else {
    banner.style.display = 'none';
  }

  // Header
  document.getElementById('hdr-id-label').textContent = mode === 'capture' ? 'Lead:' : 'ID:';
  document.getElementById('hdr-id').textContent =
    mode === 'capture' ? (state.leadId ? `#${state.leadId}` : '…') : (state.wwrId || '—');
  document.getElementById('hdr-board').textContent = BOARD_LABELS[state.provider] || state.provider || '—';
  updateConfidenceBadge(e._method);
  renderApplicationStatus(state.applicationStatus);
  renderApplicationCompletion(state.applicationCompletion);
  renderApplicationQA(state.applicationQA);
  renderProfileFields(state.profileFields);
  renderApplicationContext(state.applicationContext, state.applicationFields);
  recordApplicationFieldObservations(state).catch(() => {});

  // Company match picker only applies in capture mode -- enrich mode keeps
  // the plain text field (the JobPosting's Company link is set elsewhere).
  const companyMatches = document.getElementById('company-matches');
  if (mode === 'capture') {
    searchCompanyMatches(coalesce(e, 'company'));
  } else if (companyMatches) {
    companyMatches.style.display = 'none';
    companyMatches.innerHTML = '';
  }

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
  const safeApplyUrl = applyUrl ? safeHttpUrl(applyUrl) : null;
  if (safeApplyUrl) { applyLink.href = safeApplyUrl; applyLink.style.display = 'block'; }
  else               { applyLink.style.display = 'none'; }

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
  // description_text (innerText) already has real paragraph/bullet line
  // breaks -- collapsing all \s+ (including \n) to one space flattened
  // every capture into an unreadable wall of text. Only fold horizontal
  // whitespace and excess blank lines; keep the line breaks.
  const rawDesc  = coalesce(e, 'description_text', 'description_html');
  const cleanDesc = rawDesc
    ? rawDesc.replace(/<\/(p|div|h[1-6])>/gi, '\n\n').replace(/<li[^>]*>|<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, ' ')
             .split('\n').map(line => line.replace(/[ \t]+/g, ' ').trim()).join('\n')
             .replace(/\n{3,}/g, '\n\n')
             .trim()
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
  btn.textContent     = mode === 'capture' ? 'Ingest' : 'Submit to WWWorkRemote';
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
  const safe = safeHttpUrl(this.value.trim());
  if (safe) { link.href = safe; link.style.display = 'block'; }
  else      { link.style.display = 'none'; }
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
  try {
    chrome.runtime.sendMessage({ type: 'DIAG_LOG', level: 'panel', text: msg, ts: Date.now() });
  } catch (_) { /* ignore */ }
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
    // Capture mode only: set when the user picked an existing company from
    // the match list; null means "create new" (or field left untouched).
    company_id:       currentState?.mode === 'capture' ? selectedCompanyId : null,
  };
}

// ── Submit ────────────────────────────────────────────────────────────────

document.getElementById('submit-btn').addEventListener('click', async () => {
  const isCapture = currentState?.mode === 'capture';
  const readyLabel = isCapture ? 'Ingest' : 'Submit to WWWorkRemote';

  if (!isCapture && !currentState?.wwrId) {
    setStatus('No job loaded — open a job page first', 'var(--red)');
    return;
  }
  const btn = document.getElementById('submit-btn');
  btn.disabled    = true;
  btn.textContent = isCapture ? 'Ingesting…' : 'Submitting…';
  setStatus('Sending to WWWorkRemote…', 'var(--purple)');

  try {
    const result = await new Promise((resolve, reject) => {
      chrome.runtime.sendMessage(
        { type: 'SUBMIT_JOB', editedData: readForm() },
        (response) => {
          if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
          else resolve(response);
        }
      );
    });

    if (result?.ok) {
      btn.textContent     = isCapture ? '✓ Ingested' : '✓ Submitted';
      btn.style.background = 'var(--green)';
      setStatus(result.message || '✨ Sync complete', 'var(--green)');
      if (isCapture) {
        refreshIngestionLog();
        if (result.leadId) await showLastIngestedLink(currentState?.extracted?.title, result.leadId);
        // Brief pause so the "✓ Ingested" confirmation is actually seen
        // before the panel resets for the next posting -- this is a
        // one-job-at-a-time workflow, not a "leave it submitted" one.
        setTimeout(resetForNextCapture, 1200);
      } else {
        await showRecordLinks(currentState?.extracted?.title, result.jobPostingId || currentState?.wwrId, result.leadId);
        refreshIngestionLog();
      }
    } else {
      throw new Error(result?.error || 'Unknown error from server');
    }
  } catch (err) {
    btn.disabled    = false;
    btn.textContent = readyLabel;
    setStatus('✗ ' + err.message, 'var(--red)');
  }
});

async function showRecordLinks(title, jobPostingId, leadId) {
  const el = document.getElementById('record-links');
  if (!el || !jobPostingId) return;
  const { base: apiBase } = await getApiConfig();

  el.innerHTML = '';
  const posting = document.createElement('a');
  posting.href = `${apiBase}/job_postings/${encodeURIComponent(jobPostingId)}`;
  posting.target = '_blank';
  posting.rel = 'noopener';
  posting.textContent = `View WWWorkRemote job #${jobPostingId} →`;
  el.appendChild(posting);
  if (leadId) {
    const lead = document.createElement('a');
    lead.href = `${apiBase}/admin/leads/${encodeURIComponent(leadId)}`;
    lead.target = '_blank';
    lead.rel = 'noopener';
    lead.textContent = `View lead #${leadId} →`;
    el.appendChild(document.createTextNode(' · '));
    el.appendChild(lead);
  }
  el.dataset.title = title || '';
  renderCurrentEnrichment(title, jobPostingId, leadId, apiBase);
}

// Shown in the empty state after a reset so the "did it work?" answer is
// still visible (and clickable, to confirm on wwworkremote.localhost)
// right up until the next capture overwrites it.
async function showLastIngestedLink(title, leadId) {
  const el = document.getElementById('last-ingested');
  if (!el) return;
  const { base: apiBase } = await getApiConfig();

  el.innerHTML = '';
  el.appendChild(document.createTextNode(`Last ingested: ${title || '(untitled)'} — `));
  const link = document.createElement('a');
  link.href = `${apiBase}/admin/leads/${leadId}`;
  link.target = '_blank';
  link.rel = 'noopener';
  link.textContent = `View Lead #${leadId} →`;
  el.appendChild(link);
  el.style.display = 'block';
}

function resetForNextCapture() {
  chrome.storage.session.remove(SESSION_KEY);
  currentState = null;
  // The next capture's diagnostics array starts fresh from storage's
  // perspective (new session state) but the log itself stays on-screen
  // (a running history, not a per-job one) -- resync the counter so new
  // entries keep appending instead of looking like they're already "seen".
  diagRenderedCount = 0;
  showEmpty();
}

// ── Storage listeners ─────────────────────────────────────────────────────

function stateWithoutDiagnostics(state) {
  const copy = { ...state };
  delete copy.diagnostics;
  return copy;
}

chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== 'session') return;
  const change = changes[SESSION_KEY];
  if (!change?.newValue) return;

  const newState = change.newValue;

  const oldFieldKeys = (currentState?.applicationFields || []).map(field => field.key).join('|');
  const newFieldKeys = (newState.applicationFields || []).map(field => field.key).join('|');
  if (currentState && oldFieldKeys !== newFieldKeys && newState.applicationContext) {
    const edits = Object.fromEntries([...document.querySelectorAll('.app-field-row')].map(row =>
      [row.dataset.fieldKey, row.querySelector('.app-field-answer')?.value || '']));
    currentState = newState;
    renderApplicationContext(newState.applicationContext, newState.applicationFields || []);
    recordApplicationFieldObservations(newState).catch(() => {});
    for (const [key, value] of Object.entries(edits)) {
      const input = document.querySelector(`.app-field-row[data-field-key="${CSS.escape(key)}"] .app-field-answer`);
      if (input) input.value = value;
    }
    setStatus(`${newState.applicationFields.length} visible fields discovered`, 'var(--green)');
    return;
  }

  renderNewDiagEntries(newState.diagnostics);

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
      const clean   = rawDesc.replace(/<\/(p|div|h[1-6])>/gi, '\n\n').replace(/<li[^>]*>|<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, ' ')
                              .split('\n').map(line => line.replace(/[ \t]+/g, ' ').trim()).join('\n')
                              .replace(/\n{3,}/g, '\n\n')
                              .trim();
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

  // Element-picker result: content.js reports a taught field independently
  // of any request/response cycle (the click can happen an arbitrary amount
  // of time after PICKER_START), so this has to be handled here rather than
  // as a direct message response.
  if (newState.pickerResult) {
    handlePickerResult(newState.pickerResult);
    return;
  }

  // Diagnostics-only patch (a DIAG_LOG entry during extraction/submit, which
  // patches the whole stored state including `extracted` even though it
  // didn't actually change) -- already rendered above via
  // renderNewDiagEntries. A capture fires ~8-10 of these in under a second;
  // falling through to a full populateForm() for each one was re-triggering
  // the live company search that many times, visibly jittering the panel.
  if (currentState && JSON.stringify(stateWithoutDiagnostics(newState)) === JSON.stringify(stateWithoutDiagnostics(currentState))) {
    return;
  }

  // Full repopulate (new job or full re-read)
  populateForm(newState);
});

// ── Diagnostics log (collapsed by default, mirrors LOG*/setStatus) ─────────

let diagRenderedCount = 0;

document.getElementById('diag-toggle').addEventListener('click', () => {
  const body   = document.getElementById('diag-log');
  const toggle = document.getElementById('diag-toggle');
  const open   = body.style.display !== 'none';
  body.style.display = open ? 'none' : 'block';
  toggle.textContent = open ? '▸ Show diagnostics log' : '▾ Hide diagnostics log';
});

function appendDiagEntry(list, entry) {
  const row = document.createElement('div');
  row.className = `diag-entry level-${entry.level}`;

  const head = document.createElement('div');
  head.className = 'diag-entry-head';
  const time = new Date(entry.ts).toLocaleTimeString([], { hour12: false });
  const tsEl = document.createElement('span');
  tsEl.className = 'diag-ts';
  tsEl.textContent = time;
  const textEl = document.createElement('span');
  textEl.className = 'diag-text';
  textEl.textContent = entry.text; // untrusted (may echo scraped page content) -- textContent only
  head.append(tsEl, textEl);
  row.append(head);

  // entry.detail carries structured data (raw JSON-LD, extraction metadata)
  // -- collapsed by default via native <details>, no extra JS needed.
  if (entry.detail) {
    const details = document.createElement('details');
    details.className = 'diag-detail';
    const summary = document.createElement('summary');
    summary.textContent = 'detail';
    const pre = document.createElement('pre');
    pre.textContent = entry.detail; // untrusted (scraped page data) -- textContent only
    details.append(summary, pre);
    row.append(details);
  }

  list.appendChild(row);
}

// Renders only entries added since the last call -- diagnostics rides along
// on every storage patch (background.js spreads it forward unchanged), not
// just ones meant for the log, so this has to be additive, not a full redraw.
function renderNewDiagEntries(diagnostics) {
  if (!Array.isArray(diagnostics) || diagnostics.length <= diagRenderedCount) return;
  const list = document.getElementById('diag-log');
  if (!list) return;
  diagnostics.slice(diagRenderedCount).forEach(entry => appendDiagEntry(list, entry));
  diagRenderedCount = diagnostics.length;
  list.scrollTop = list.scrollHeight;
}

// ── Ingestion log (persistent, visible in every panel state) ───────────────

const LOG_STATUS = {
  captured:  { label: 'Captured',  bg: '#3a3000', color: 'var(--yellow)' },
  matched:   { label: 'Matched',   bg: '#3a3000', color: 'var(--yellow)' },
  promoted:  { label: 'Promoted',  bg: '#0d3320', color: 'var(--green)' },
  discarded: { label: 'Discarded', bg: '#2d2f3d', color: 'var(--comment)' },
  duplicate: { label: 'Duplicate', bg: '#3a2400', color: 'var(--orange)' },
};

async function refreshIngestionLog() {
  const list = document.getElementById('ingestion-log-list');
  if (!list) return;

  try {
    const { base: apiBase, authHeader } = await getApiConfig();
    const headers = {};
    if (authHeader) headers['Authorization'] = authHeader;
    const response = await fetch(`${apiBase}/api/leads`, { headers });
    if (!response.ok) throw new Error(`Server error ${response.status}`);
    const leads = await response.json();
    renderIngestionLog(leads.slice(0, 10), apiBase);
    if (currentState?.mode === 'enrich' && currentState.wwrId) {
      renderCurrentEnrichment(currentState.extracted?.title, currentState.wwrId, null, apiBase);
    }
  } catch (err) {
    list.innerHTML = `<div class="ingestion-log-empty">Log unavailable: ${escapeHtml(err.message)}</div>`;
  }
}

function renderIngestionLog(leads, apiBase) {
  const list = document.getElementById('ingestion-log-list');
  if (!list) return;

  if (!leads.length) {
    list.innerHTML = '<div class="ingestion-log-empty">Nothing captured yet.</div>';
    return;
  }

  list.innerHTML = leads.map(lead => {
    const status = LOG_STATUS[lead.status] || LOG_STATUS.captured;
    const title = escapeHtml(lead.title || '(untitled)');
    const company = escapeHtml(lead.company_name || '');
    return `
      <a class="ingestion-log-item" href="${apiBase}/admin/leads/${lead.id}" target="_blank" rel="noopener">
        <div class="ilog-main">
          <div class="ilog-title">${title}</div>
          <div class="ilog-company">${company}</div>
        </div>
        <span class="ilog-status" style="background:${status.bg};color:${status.color};">${status.label}</span>
      </a>
    `;
  }).join('');
}

function renderCurrentEnrichment(title, jobPostingId, leadId, apiBase) {
  const list = document.getElementById('ingestion-log-list');
  if (!list || !jobPostingId || list.querySelector(`[data-job-posting-id="${CSS.escape(String(jobPostingId))}"]`)) return;

  const item = document.createElement('a');
  item.className = 'ingestion-log-item ingestion-log-current';
  item.dataset.jobPostingId = jobPostingId;
  item.href = `${apiBase}/job_postings/${encodeURIComponent(jobPostingId)}`;
  item.target = '_blank';
  item.rel = 'noopener';
  item.innerHTML = `<div class="ilog-main"><div class="ilog-title">${escapeHtml(title || `Job #${jobPostingId}`)}</div><div class="ilog-company">WWWorkRemote job #${escapeHtml(jobPostingId)}</div></div><span class="ilog-status" style="background:#0d3320;color:var(--green);">Enriched</span>`;
  list.prepend(item);
}

// ── Element picker ("Teach the extractor") ──────────────────────────────────
// FIELD_MAP maps DOM input ids to extracted-data keys; teaching always
// targets the first key (matches the same priority order content.js's own
// coalesce() already uses when a field has more than one, e.g. skills/tags).

const DATA_KEY_TO_INPUT = Object.fromEntries(
  Object.entries(FIELD_MAP).map(([inputId, keys]) => [keys[0], inputId])
);

function fieldElId(inputId) {
  return inputId.replace(/^f-/, 'fld-');
}

function markTaught(fieldId) {
  const dot = document.getElementById(`src-${fieldId.replace(/^fld-/, '')}`);
  if (!dot) return;
  dot.classList.remove('found', 'missing');
  dot.classList.add('taught');
  dot.title = 'Taught via element picker';
}

function injectTeachButtons() {
  for (const [inputId, keys] of Object.entries(FIELD_MAP)) {
    const field  = document.getElementById(fieldElId(inputId));
    const header = field?.querySelector('.field-header');
    if (!header || header.querySelector('.teach-btn')) continue;

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'field-action teach-btn';
    btn.title = 'Teach: click here, then click the element on the page with the correct value';
    btn.textContent = '🎯';
    btn.addEventListener('click', () => startTeaching(keys[0], btn));
    header.appendChild(btn);
  }
}

function startTeaching(dataKey, btn) {
  btn.disabled = true;
  setStatus('Click the element on the page with the correct value… (Esc to cancel)', 'var(--purple)');
  chrome.runtime.sendMessage({ type: 'PICKER_START', fieldName: dataKey }, (response) => {
    if (!response?.ok) {
      setStatus('✗ ' + (response?.error || 'Could not start picker'), 'var(--red)');
      btn.disabled = false;
    }
    // On success, the button re-enables in handlePickerResult once the
    // click (or Escape) comes back via storage — that can take any amount
    // of time, so there's nothing more to do here.
  });
}

function clearPickerResult() {
  chrome.storage.session.get(SESSION_KEY, (data) => {
    const state = data?.[SESSION_KEY];
    if (state) chrome.storage.session.set({ [SESSION_KEY]: { ...state, pickerResult: null } });
  });
}

function startApplicationMapping(fieldKey, btn) {
  setStatus('Click the corresponding Workday field on the page… (Esc to cancel)', 'var(--purple)');
  chrome.runtime.sendMessage({ type: 'PICKER_START', fieldName: fieldKey, mapping: true }, (response) => {
    if (!response?.ok) {
      btn.disabled = false;
      btn.textContent = 'Map';
      setStatus('✗ ' + (response?.error || 'Could not start mapping picker'), 'var(--red)');
    }
  });
}

function renderApplicationMappingDraft(result) {
  const row = document.querySelector(`.app-field-row[data-field-key="${CSS.escape(result.fieldName)}"]`);
  if (!row) return;
  row.querySelector('.app-map-editor')?.remove();
  const suggestion = semanticSuggestion({ label: row.querySelector('.app-field-label span')?.textContent || '' });
  const descriptor = result.elementDescriptor || {};
  const editor = document.createElement('div');
  editor.className = 'app-map-editor';
  editor.innerHTML = `
    <input class="app-map-key" type="text" placeholder="semantic key (e.g. profile.email)" value="${escapeHtml(suggestion.key)}">
    <select class="app-map-kind">
      ${['profile', 'persona', 'question', 'manual'].map(kind => `<option value="${kind}" ${kind === suggestion.kind ? 'selected' : ''}>${kind}</option>`).join('')}
    </select>
    <button type="button" class="app-map-save app-map-btn">Save map</button>`;
  row.appendChild(editor);
  editor.querySelector('.app-map-key').focus();
  editor.querySelector('.app-map-save').addEventListener('click', () => {
    const saveButton = editor.querySelector('.app-map-save');
    saveButton.disabled = true;
    saveApplicationMapping(row, result, descriptor)
      .catch(err => setStatus('✗ Mapping save failed: ' + err.message, 'var(--red)'))
      .finally(() => { saveButton.disabled = false; });
  });
}

async function saveApplicationMapping(row, result, descriptor) {
  const semanticKey = row.querySelector('.app-map-key').value.trim();
  const sourceKind = row.querySelector('.app-map-kind').value;
  if (!semanticKey) { setStatus('Enter a semantic key before saving', 'var(--yellow)'); return; }
  const { base: apiBase, authHeader } = await getApiConfig();
  const headers = { 'Content-Type': 'application/json', ...(authHeader ? { Authorization: authHeader } : {}) };
  const fieldLabel = row.querySelector('.app-field-label span')?.textContent || result.fieldName;
  const response = await fetch(`${apiBase}/api/v0/job_postings/${currentState.wwrId}/application_field_mappings`, {
    method: 'POST', headers,
    body: JSON.stringify({ application_field_mapping: {
      field_key: result.fieldName, field_label: fieldLabel, semantic_key: semanticKey,
      semantic_label: semanticKey, source_kind: sourceKind, provider: currentState.provider,
      page_step: result.pageStep, page_url: currentState.pageUrl, page_title: result.pageTitle,
      element_fingerprint: descriptor.selector || result.candidateSelector,
      element_descriptor: descriptor,
      context: { required: row.querySelector('.app-field-label b') !== null, clicked_label: descriptor.label || fieldLabel },
    } }),
  });
  const data = await response.json();
  if (!response.ok || !data.success) throw new Error(data.error || `HTTP ${response.status}`);
  currentState.applicationContext.mappings = [data.mapping, ...(currentState.applicationContext.mappings || [])];
  chrome.storage.session.set({ [SESSION_KEY]: currentState });
  renderApplicationContext(currentState.applicationContext, currentState.applicationFields || []);
  setStatus(`${fieldLabel} mapped to ${semanticKey}`, 'var(--green)');
}

async function handlePickerResult(result) {
  if (result.mapping) {
    const btn = document.querySelector(`.app-field-row[data-field-key="${CSS.escape(result.fieldName)}"] .app-map-btn`);
    if (btn) { btn.disabled = false; btn.textContent = 'Map'; }
    if (result.cancelled) {
      setStatus('Mapping cancelled', 'var(--comment)');
      clearPickerResult();
      return;
    }
    renderApplicationMappingDraft(result);
    setStatus('Review the semantic source, then save the mapping', 'var(--purple)');
    clearPickerResult();
    return;
  }
  const inputId = DATA_KEY_TO_INPUT[result.fieldName];
  const btn = inputId ? document.querySelector(`#${fieldElId(inputId)} .teach-btn`) : null;
  if (btn) btn.disabled = false;

  if (result.cancelled) {
    setStatus('Teach cancelled', 'var(--comment)');
    clearPickerResult();
    return;
  }

  if (inputId) {
    setVal(inputId, result.value, fieldElId(inputId), null);
    markTaught(fieldElId(inputId));
  }
  await saveExtractionRule(result);
  clearPickerResult();
}

async function saveExtractionRule(result) {
  setStatus('Saving learned rule…', 'var(--purple)');
  try {
    const { base: apiBase, authHeader } = await getApiConfig();
    const headers = { 'Content-Type': 'application/json' };
    if (authHeader) headers['Authorization'] = authHeader;
    const response = await fetch(`${apiBase}/api/extraction_rules`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        provider: currentState?.provider || 'generic',
        field_name: result.fieldName,
        element_html: result.elementHtml,
        parent_html: result.parentHtml,
        candidate_selector: result.candidateSelector,
        source_url: currentState?.pageUrl,
      }),
    });
    if (!response.ok) throw new Error(`Server error ${response.status}`);
    setStatus('✓ Taught — future postings on this board will auto-fill this field', 'var(--green)');
  } catch (e) {
    setStatus('✗ Learned rule not saved: ' + e.message, 'var(--red)');
  }
}

// ── Init ──────────────────────────────────────────────────────────────────

function init() {
  const manifest = chrome.runtime.getManifest();
  const buildStamp = document.getElementById('build-stamp');
  if (buildStamp) {
    buildStamp.textContent = `WWWR EXT ${manifest.version} · MV${manifest.manifest_version} · LOCAL UNPACKED`;
    buildStamp.title = 'Extension manifest/build information';
  }
  const headerBuildStamp = document.getElementById('header-build-stamp');
  if (headerBuildStamp) headerBuildStamp.textContent = `v${manifest.version}`;
  chrome.storage.session.get(SESSION_KEY, (data) => {
    const state = data?.[SESSION_KEY];
    if (state?.extracted) populateForm(state);
    else                  showEmpty();
    renderNewDiagEntries(state?.diagnostics);
  });
  injectTeachButtons();
  refreshIngestionLog();
}

init();

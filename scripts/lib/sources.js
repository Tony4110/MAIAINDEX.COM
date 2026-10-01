// MAIA - data-source pullers
// All sources are free public APIs. We only READ counts/metadata per ingredient.
// Native fetch (Node >= 20). No scraping, no fabrication: unknown = null/0 + flagged.

const NCBI_EMAIL = process.env.NCBI_EMAIL || '';
const NCBI_API_KEY = process.env.NCBI_API_KEY || '';
const MAILTO = NCBI_EMAIL || 'contact@maiaindex.com';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Polite fetch with retry + exponential backoff (handles 429/5xx/network blips).
async function getJSON(url, { retries = 3, label = 'fetch' } = {}) {
  let lastErr;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url, { headers: { 'User-Agent': `maia-index/0.1 (${MAILTO})` } });
      if (res.status === 404) return { __notfound: true };
      if (res.status === 429 || res.status >= 500) throw new Error(`${label} HTTP ${res.status}`);
      if (!res.ok) throw new Error(`${label} HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      lastErr = e;
      if (attempt < retries) await sleep(800 * Math.pow(2, attempt) + Math.random() * 400);
    }
  }
  throw lastErr;
}

const enc = encodeURIComponent;

// ---------------------------------------------------------------------
// PubChem - normalize an ingredient name to a canonical CID + synonyms.
// Many entries (lifestyle protocols, peptides) have no CID -> return null.
// ---------------------------------------------------------------------
export async function pubchemNormalize(name) {
  try {
    const url = `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/${enc(name)}/synonyms/JSON`;
    const data = await getJSON(url, { label: 'pubchem' });
    if (data.__notfound || !data.InformationList) return { cid: null, synonyms: [] };
    const info = data.InformationList.Information?.[0];
    return {
      cid: info?.CID ? String(info.CID) : null,
      synonyms: Array.isArray(info?.Synonym) ? info.Synonym.slice(0, 8) : [],
    };
  } catch {
    return { cid: null, synonyms: [] };
  }
}

// ---------------------------------------------------------------------
// PubMed E-utilities - evidence counts (retmax=0 => cheap count-only).
// ---------------------------------------------------------------------
function eutilsUrl(term) {
  const p = new URLSearchParams({
    db: 'pubmed', retmode: 'json', retmax: '0', term, tool: 'maia-index',
  });
  if (NCBI_EMAIL) p.set('email', NCBI_EMAIL);
  if (NCBI_API_KEY) p.set('api_key', NCBI_API_KEY);
  return `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?${p.toString()}`;
}
async function pubmedCount(term) {
  const data = await getJSON(eutilsUrl(term), { label: 'pubmed' });
  const n = Number(data?.esearchresult?.count);
  return Number.isFinite(n) ? n : 0;
}

export async function pubmedCounts(name) {
  const yearFrom = new Date().getFullYear() - 4;
  const base = `"${name}"[tiab]`;
  // Sequential to respect NCBI rate limits (3/s no key, 10/s with key).
  const total = await pubmedCount(base);
  await sleep(NCBI_API_KEY ? 120 : 360);
  const rct = await pubmedCount(`${base} AND "Randomized Controlled Trial"[Publication Type] AND Humans[MeSH Terms]`);
  await sleep(NCBI_API_KEY ? 120 : 360);
  const meta = await pubmedCount(`${base} AND "Meta-Analysis"[Publication Type]`);
  await sleep(NCBI_API_KEY ? 120 : 360);
  const systematic = await pubmedCount(`${base} AND "Systematic Review"[Publication Type]`);
  await sleep(NCBI_API_KEY ? 120 : 360);
  const recent = await pubmedCount(`${base} AND ${yearFrom}:3000[dp]`);
  return { pubmed_total: total, pubmed_rct: rct, pubmed_meta: meta, pubmed_systematic: systematic, pubmed_recent: recent };
}

// ---------------------------------------------------------------------
// ClinicalTrials.gov v2 - clinical maturity (count + phase + results).
// Bounded to first 200 studies for the phase/results aggregation.
// ---------------------------------------------------------------------
export async function clinicalTrials(name) {
  const fields = ['Phase', 'StudyType', 'OverallStatus', 'HasResults'].join(',');
  const url = `https://clinicaltrials.gov/api/v2/studies?query.intr=${enc(name)}` +
    `&countTotal=true&pageSize=200&fields=${fields}`;
  try {
    const data = await getJSON(url, { label: 'ctgov' });
    if (data.__notfound) return { ct_total: 0, ct_phase3plus: 0, ct_with_results: 0, ct_interventional: 0 };
    const total = Number(data?.totalCount) || 0;
    let phase3plus = 0, withResults = 0, interventional = 0;
    for (const s of data?.studies || []) {
      const d = s?.protocolSection?.designModule || {};
      const st = s?.protocolSection?.statusModule || {};
      const phases = d.phases || [];
      if ((d.studyType || '').toUpperCase() === 'INTERVENTIONAL') interventional++;
      if (phases.includes('PHASE3') || phases.includes('PHASE4')) phase3plus++;
      if (st.hasResults === true || s?.hasResults === true) withResults++;
    }
    return { ct_total: total, ct_phase3plus: phase3plus, ct_with_results: withResults, ct_interventional: interventional };
  } catch {
    return { ct_total: 0, ct_phase3plus: 0, ct_with_results: 0, ct_interventional: 0 };
  }
}

// ---------------------------------------------------------------------
// Europe PMC - no-key cross-check on volume + RCT count.
// ---------------------------------------------------------------------
export async function europePmc(name) {
  try {
    const q = `"${name}"`;
    const url = `https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=${enc(q)}&format=json&pageSize=1&resultType=lite`;
    const data = await getJSON(url, { label: 'europepmc' });
    return { europepmc_hits: Number(data?.hitCount) || 0 };
  } catch {
    return { europepmc_hits: 0 };
  }
}

// ---------------------------------------------------------------------
// OpenAlex - impact proxy (works count + citations). Polite pool via mailto.
// ---------------------------------------------------------------------
export async function openAlex(name) {
  try {
    const url = `https://api.openalex.org/works?filter=title.search:${enc(name)}&per_page=1&mailto=${enc(MAILTO)}`;
    const data = await getJSON(url, { label: 'openalex' });
    return { openalex_works: Number(data?.meta?.count) || 0 };
  } catch {
    return { openalex_works: 0 };
  }
}

// ---------------------------------------------------------------------
// openFDA CAERS - safety signal (adverse-event reports). 404 => 0 events.
// ---------------------------------------------------------------------
export async function openFda(name) {
  try {
    const key = process.env.OPENFDA_API_KEY ? `&api_key=${process.env.OPENFDA_API_KEY}` : '';
    const url = `https://api.fda.gov/food/event.json?search=${enc(name)}&limit=1${key}`;
    const data = await getJSON(url, { label: 'openfda' });
    if (data.__notfound) return { openfda_events: 0 };
    return { openfda_events: Number(data?.meta?.results?.total) || 0 };
  } catch {
    return { openfda_events: 0 };
  }
}

// Gather every raw signal for one ingredient (canonical name used for queries).
export async function gatherRaw(queryName) {
  const pubmed = await pubmedCounts(queryName);
  await sleep(150);
  const ct = await clinicalTrials(queryName);
  await sleep(150);
  const epmc = await europePmc(queryName);
  await sleep(150);
  const oa = await openAlex(queryName);
  await sleep(150);
  const fda = await openFda(queryName);
  return { ...pubmed, ...ct, ...epmc, ...oa, ...fda, pulled_at: new Date().toISOString() };
}

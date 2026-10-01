// Quick offline sanity check of the scoring logic (no network, no DB).
// Run: npm run score:test
import { computeScore, METHODOLOGY_VERSION } from './lib/score.js';

const cases = {
  'well-established (meta + many RCTs)': {
    pubmed_total: 4200, pubmed_rct: 180, pubmed_meta: 45, pubmed_systematic: 60, pubmed_recent: 900,
    ct_total: 90, ct_phase3plus: 20, ct_with_results: 40, ct_interventional: 80, europepmc_hits: 5000, openfda_events: 30,
  },
  'promising (a few human RCTs, no meta)': {
    pubmed_total: 41, pubmed_rct: 9, pubmed_meta: 0, pubmed_systematic: 0, pubmed_recent: 28,
    ct_total: 9, ct_phase3plus: 1, ct_with_results: 3, ct_interventional: 8, europepmc_hits: 55, openfda_events: 2,
  },
  'preclinical only (literature, no human trials)': {
    pubmed_total: 300, pubmed_rct: 0, pubmed_meta: 0, pubmed_systematic: 0, pubmed_recent: 120,
    ct_total: 0, ct_phase3plus: 0, ct_with_results: 0, ct_interventional: 0, europepmc_hits: 400, openfda_events: 0,
  },
  'no data': {},
};

console.log(`MAIA scoring ${METHODOLOGY_VERSION}\n`);
let ok = true;
for (const [label, raw] of Object.entries(cases)) {
  const s = computeScore(raw);
  const subsum = ['sub_best_tier','sub_trial_depth','sub_consistency','sub_effect_size','sub_safety','sub_directness']
    .reduce((a, k) => a + s[k], 0);
  const inRange = s.credibility_score >= 0 && s.credibility_score <= 100 &&
                  s.confidence_score >= 0 && s.confidence_score <= 100;
  if (!inRange) ok = false;
  console.log(`• ${label}`);
  console.log(`    credibility=${s.credibility_score}  (tier ${s.sub_best_tier}/30, depth ${s.sub_trial_depth}/20, consist ${s.sub_consistency}/20, effect ${s.sub_effect_size}/15, safety ${s.sub_safety}/10, direct ${s.sub_directness}/5  sum=${subsum.toFixed(2)})`);
  console.log(`    confidence=${s.confidence_score} -> ${s.confidence_level}\n`);
}
// Monotonicity: established should outscore promising should outscore preclinical should outscore none.
const a = computeScore(cases['well-established (meta + many RCTs)']).credibility_score;
const b = computeScore(cases['promising (a few human RCTs, no meta)']).credibility_score;
const c = computeScore(cases['preclinical only (literature, no human trials)']).credibility_score;
const d = computeScore(cases['no data']).credibility_score;
const mono = a > b && b > c && c > d;
console.log(`monotonic (established>promising>preclinical>none): ${mono ? 'PASS' : 'FAIL'}  [${a} > ${b} > ${c} > ${d}]`);
if (!ok || !mono) { console.error('SCORE TEST FAILED'); process.exit(1); }
console.log('SCORE TEST PASSED');

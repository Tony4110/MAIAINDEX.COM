// MAIA - dual-axis scoring engine (v1.0)
//
//  AXIS 1  Credibility Score (0-100) = strength of the EVIDENCE.
//          6 dimensions: Best Tier 30 / Trial Depth 20 / Consistency 20 /
//          Effect 15 / Safety 10 / Directness 5.
//  AXIS 2  Evidence Confidence (0-100 -> High/Moderate/Low/Preliminary) =
//          how mature/trustworthy the data corpus is (GRADE-style), SEPARATE
//          from the score. A thin corpus can score high with LOW confidence.
//
//  Honesty rules:
//   - We NEVER prescribe. This scores the evidence, not the action.
//   - Dimensions that cannot be read from public counts (effect size,
//     directness) are PROVISIONAL in v1.0, derived conservatively from the
//     best available evidence tier, and flagged as such. A later version
//     refines them with a human/LLM extraction pass.

export const METHODOLOGY_VERSION = 'v1.0';

const clamp = (x, lo, hi) => Math.max(lo, Math.min(hi, x));
const round2 = (x) => Math.round(x * 100) / 100;
// log-saturation: diminishing returns. sat(0)=0, sat(k)~0.5-ish, -> 1.
const sat = (x, k) => (x <= 0 ? 0 : Math.min(1, Math.log(1 + x) / Math.log(1 + k)));

// Best available evidence tier -> a 0..100 tier value (meta cap applies naturally
// because we can only claim T1 when meta/systematic publication types exist).
function bestTierValue(r) {
  if ((r.pubmed_meta || 0) > 0 || (r.pubmed_systematic || 0) > 0) return 100; // T1
  if ((r.pubmed_rct || 0) > 0 || (r.ct_with_results || 0) > 0) return 80;     // T2 human RCT
  if ((r.ct_total || 0) > 0) return 55;                                       // T3 registered interventional
  if ((r.pubmed_total || 0) > 0 || (r.europepmc_hits || 0) > 0) return 35;    // literature exists, mix unknown
  return 0;                                                                   // T0 no data
}

export function computeScore(raw) {
  const r = raw || {};

  // --- Dim 1: Best Evidence Tier (30) ---
  const tierVal = bestTierValue(r);
  const sub_best_tier = round2((tierVal / 100) * 30);

  // --- Dim 2: Human Trial Depth (20) - phase-weighted, log-saturated ---
  const weighted =
    (r.pubmed_rct || 0) * 0.6 +
    (r.ct_phase3plus || 0) * 1.0 +
    (r.ct_with_results || 0) * 0.5 +
    Math.max((r.ct_interventional || 0) - (r.ct_phase3plus || 0), 0) * 0.3;
  const sub_trial_depth = round2(sat(weighted, 15) * 20);

  // --- Dim 3: Consistency / replication (20) - proxy on independent human studies ---
  const independent = (r.pubmed_rct || 0) + (r.ct_with_results || 0);
  const sub_consistency = round2(sat(independent, 12) * 20);

  // --- Dim 5: Safety (10) - only credited once an evidence base exists
  //     (absence of reports for an unstudied substance is not reassuring);
  //     adverse-event volume pulls it down, with a bounded penalty. ---
  const sub_safety = tierVal === 0
    ? 0
    : round2(clamp(10 - Math.min(6, Math.log10(1 + (r.openfda_events || 0)) * 2), 0, 10));

  // --- Dims 4 & 6: PROVISIONAL in v1.0 (derived from tier, flagged) ---
  const tierFactor = tierVal / 100; // 0..1
  const sub_effect_size = round2(tierFactor * 0.6 * 15);   // placeholder pending extraction
  const sub_directness = round2(tierFactor * 0.7 * 5);     // placeholder pending extraction

  const credibility_score = round2(clamp(
    sub_best_tier + sub_trial_depth + sub_consistency + sub_effect_size + sub_safety + sub_directness,
    0, 100
  ));

  // --- AXIS 2: Evidence Confidence (0-100) ---
  const volume = sat((r.pubmed_total || 0) + (r.ct_total || 0) * 3, 300);      // corpus size
  const replication = sat(independent, 10);                                    // independent human studies
  const totalPubs = Math.max(r.pubmed_total || 0, 1);
  const recency = clamp((r.pubmed_recent || 0) / totalPubs, 0, 1);             // share recent
  const completeness = (r.ct_total || 0) > 0 ? clamp((r.ct_with_results || 0) / r.ct_total, 0, 1) : 0.3;
  const confidence_score = round2(clamp(
    volume * 40 + replication * 30 + recency * 15 + completeness * 15,
    0, 100
  ));
  const confidence_level =
    confidence_score >= 80 ? 'High' :
    confidence_score >= 60 ? 'Moderate' :
    confidence_score >= 40 ? 'Low' : 'Preliminary';

  return {
    credibility_score,
    sub_best_tier,
    sub_trial_depth,
    sub_consistency,
    sub_effect_size,
    sub_safety,
    sub_directness,
    confidence_score,
    confidence_level,
  };
}

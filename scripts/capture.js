// MAIA - daily capture orchestrator
//
// For each active ingredient:
//   1. pull raw evidence signals (PubChem/PubMed/ClinicalTrials/EuropePMC/OpenAlex/openFDA)
//   2. compute the dual-axis score
//   3. append a snapshot to score_history (the moat - never overwritten)
//   4. upsert score_meta (current state + momentum, with Alcyone's Baseline rule)
//   5. log the run in ingestion_runs
//
// Runs in GitHub Actions. Writes use SUPABASE_SERVICE_ROLE_KEY (a GitHub secret,
// never in chat). Set DRY_RUN=1 to run the pipeline without any DB write.

import { createClient } from '@supabase/supabase-js';
import { gatherRaw, pubchemNormalize } from './lib/sources.js';
import { computeScore, METHODOLOGY_VERSION } from './lib/score.js';

const DRY_RUN = process.env.DRY_RUN === '1';
const LIMIT = process.env.LIMIT ? Number(process.env.LIMIT) : null; // e.g. first N for a smoke test
const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || (!SERVICE_KEY && !DRY_RUN)) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env.');
  process.exit(1);
}

const db = SUPABASE_URL && SERVICE_KEY
  ? createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } })
  : null;

const today = new Date().toISOString().slice(0, 10);

async function loadIngredients() {
  const { data, error } = await db
    .from('ingredients')
    .select('id, slug, name, canonical_name, pubchem_cid')
    .eq('status', 'active')
    .order('slug');
  if (error) throw error;
  return LIMIT ? data.slice(0, LIMIT) : data;
}

// Momentum with Alcyone's rule: Baseline until >= 2 real observations; never fabricate.
async function computeMomentum(ingredientId, todayScore) {
  const { data, error } = await db
    .from('score_history')
    .select('captured_at, credibility_score')
    .eq('ingredient_id', ingredientId)
    .order('captured_at', { ascending: false })
    .limit(40);
  if (error) throw error;
  const obs = data.length;
  if (obs < 2) return { trend_30d: null, trend_label: 'Baseline', observations: obs };
  // nearest snapshot at least ~30 days old, else the oldest we have
  const cutoff = new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10);
  const ref = data.find((d) => d.captured_at <= cutoff) || data[data.length - 1];
  const delta = Math.round((todayScore - Number(ref.credibility_score)) * 100) / 100;
  const label = Math.round(delta) === 0 ? 'Stable' : delta > 0 ? 'Up' : 'Down';
  return { trend_30d: delta, trend_label: label, observations: obs };
}

async function main() {
  console.log(`MAIA capture ${METHODOLOGY_VERSION} - ${today}${DRY_RUN ? ' [DRY RUN]' : ''}`);
  let processed = 0, errors = 0;

  if (DRY_RUN && !db) {
    console.log('No DB creds -> dry run on a static sample.');
    const raw = await gatherRaw('creatine').catch((e) => ({ __err: String(e) }));
    console.log('creatine raw:', raw);
    console.log('creatine score:', computeScore(raw));
    return;
  }

  const ingredients = await loadIngredients();
  console.log(`${ingredients.length} ingredients to process.`);

  for (const ing of ingredients) {
    try {
      const queryName = ing.name; // common name = best recall on PubMed/CT
      const raw = await gatherRaw(queryName);

      // opportunistic PubChem normalization (fills canonical name + cid once)
      if (!ing.pubchem_cid) {
        const norm = await pubchemNormalize(queryName);
        if (norm.cid && !DRY_RUN) {
          await db.from('ingredients').update({ pubchem_cid: norm.cid, updated_at: new Date().toISOString() }).eq('id', ing.id);
        }
      }

      const score = computeScore(raw);

      if (DRY_RUN) {
        console.log(`  [dry] ${ing.slug}: cred=${score.credibility_score} conf=${score.confidence_level} (pubmed_total=${raw.pubmed_total}, rct=${raw.pubmed_rct}, ct=${raw.ct_total})`);
        processed++;
        continue;
      }

      // 3) append snapshot (idempotent per day via unique constraint -> upsert)
      const { error: insErr } = await db.from('score_history').upsert({
        ingredient_id: ing.id,
        captured_at: today,
        methodology_version: METHODOLOGY_VERSION,
        ...score,
        raw,
      }, { onConflict: 'ingredient_id,captured_at,methodology_version' });
      if (insErr) throw insErr;

      // 4) current state + momentum
      const mom = await computeMomentum(ing.id, score.credibility_score);
      const { error: metaErr } = await db.from('score_meta').upsert({
        ingredient_id: ing.id,
        credibility_score: score.credibility_score,
        confidence_level: score.confidence_level,
        trend_30d: mom.trend_30d,
        trend_label: mom.trend_label,
        observations: mom.observations,
        last_captured_at: today,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'ingredient_id' });
      if (metaErr) throw metaErr;

      processed++;
      if (processed % 10 === 0) console.log(`  ... ${processed}/${ingredients.length}`);
    } catch (e) {
      errors++;
      console.error(`  ERROR ${ing.slug}: ${e.message || e}`);
    }
  }

  if (!DRY_RUN) {
    await db.from('ingestion_runs').insert({
      source: 'capture',
      ingredients_processed: processed,
      errors,
      status: errors === 0 ? 'ok' : (processed > 0 ? 'partial' : 'failed'),
      notes: `${METHODOLOGY_VERSION} daily snapshot`,
    });
  }
  console.log(`Done. processed=${processed} errors=${errors}`);
  if (processed === 0) process.exit(1);
}

main().catch((e) => { console.error('FATAL', e); process.exit(1); });

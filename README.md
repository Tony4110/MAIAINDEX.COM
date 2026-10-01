# MAIA — Longevity Credibility Index

Automated evidence-aggregation index for longevity interventions.
Part of the Dreamotion venture-studio "index factory" (same engine as Alcyone / Electra).

**What it does:** every day, for ~100 supplements/interventions, it pulls public
scientific data, computes a transparent **dual-axis score**, and appends a snapshot
to history. The accumulating history (how the evidence changes over time) is the moat —
no competitor publishes evidence scores as a time series.

> This project scores the **strength of the evidence**, not a recommendation.
> It is **not medical advice** and never prescribes dosages or protocols.

## Architecture

```
public APIs ──▶ pullers ──▶ dual-axis score ──▶ Supabase
(PubMed, ClinicalTrials,     (lib/sources.js)   (lib/score.js)   score_history (append-only)
 Europe PMC, OpenAlex,                                           score_meta (current + trend)
 openFDA, PubChem)                                               ingestion_runs (health)
```

- **Capture** runs in **GitHub Actions** (daily cron), not on a server. It writes with
  the Supabase `service_role` key, stored as a **GitHub secret** — never in code.
- **Database** is set up once by pasting `db/install_01_schema.sql` then
  `db/install_02_seed_ingredients.sql` into the Supabase SQL Editor.

## Scoring (v1.0)

**Axis 1 — Credibility (0–100):** Best Evidence Tier 30 · Human Trial Depth 20 ·
Consistency 20 · Effect Size 15 · Safety 10 · Directness 5.
**Axis 2 — Evidence Confidence** (separate): High / Moderate / Low / Preliminary (GRADE-style).

Effect Size and Directness are **provisional in v1.0** (derived conservatively from the
best evidence tier) and flagged for a later human/LLM extraction pass.

## Run locally

```bash
npm install
npm run score:test      # offline scoring sanity check
DRY_RUN=1 LIMIT=5 SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run capture
```

## GitHub secrets to set (Settings → Secrets → Actions)

| Secret | Required | Notes |
|---|---|---|
| `SUPABASE_URL` | yes | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | yes | secret; bypasses RLS to write |
| `NCBI_EMAIL` | recommended | contact email for NCBI E-utilities |
| `NCBI_API_KEY` | recommended | lifts PubMed 3→10 req/s |
| `OPENFDA_API_KEY` | optional | lifts openFDA daily cap |

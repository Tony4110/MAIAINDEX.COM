-- =====================================================================
--  MAIA — Longevity Credibility Index
--  INSTALL 01 / SCHEMA  ·  v1.0  ·  2026-10-01
--  À coller tel quel dans Supabase > SQL Editor > Run.
--  Idempotent : peut être relancé sans casser l'existant.
--  Architecture : moteur "layer Alcyone" (score_history + score_meta)
--  adapté à un index DOUBLE AXE :
--    - credibility_score (0-100) = force de la preuve
--    - confidence_level          = fiabilité du corpus (style GRADE)
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1) CATALOGUE DES INTERVENTIONS (ingrédients, molécules, protocoles)
-- ---------------------------------------------------------------------
create table if not exists public.ingredients (
  id                     uuid primary key default gen_random_uuid(),
  slug                   text unique not null,              -- ex: 'nmn'
  name                   text not null,                     -- ex: 'NMN'
  canonical_name         text,                              -- nom normalisé PubChem
  category               text not null,                     -- ex: 'NAD+ boosters'
  synonyms               text[] default '{}',               -- variantes de recherche
  mechanism              text,                              -- 1 ligne
  pubchem_cid            text,                              -- rempli par le puller
  evidence_maturity_seed text,                              -- 'strong' | 'emerging' | 'preclinical'
  is_prescription        boolean default false,             -- Rx / research compound
  is_lifestyle           boolean default false,             -- protocole non-supplément
  affiliate_url          text,                              -- lien monétisé (plus tard)
  status                 text not null default 'active',    -- 'active' | 'hidden'
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create index if not exists idx_ingredients_category on public.ingredients(category);
create index if not exists idx_ingredients_status   on public.ingredients(status);

-- ---------------------------------------------------------------------
-- 2) HISTORIQUE DES SCORES  (append-only — LE MOAT)
--    Une ligne par ingrédient par snapshot. On n'écrase jamais :
--    chaque capture = un point de la courbe dans le temps.
-- ---------------------------------------------------------------------
create table if not exists public.score_history (
  id                  bigint generated always as identity primary key,
  ingredient_id       uuid not null references public.ingredients(id) on delete cascade,
  captured_at         date not null default current_date,
  methodology_version text not null default 'v1.0',

  -- AXE 1 : score de crédibilité (0-100) + ses 6 sous-dimensions
  credibility_score   numeric(5,2),        -- total /100
  sub_best_tier       numeric(5,2),        -- /30  meilleure qualité de preuve
  sub_trial_depth     numeric(5,2),        -- /20  profondeur essais humains
  sub_consistency     numeric(5,2),        -- /20  cohérence / réplication
  sub_effect_size     numeric(5,2),        -- /15  ampleur de l'effet
  sub_safety          numeric(5,2),        -- /10  signal sécurité (peut faire baisser)
  sub_directness      numeric(5,2),        -- /5   pertinence de l'issue

  -- AXE 2 : confiance dans le corpus (séparé du score)
  confidence_score    numeric(5,2),        -- 0-100 (interne)
  confidence_level    text,                -- 'High'|'Moderate'|'Low'|'Preliminary'

  -- Données brutes des sources (traçabilité totale)
  raw                 jsonb default '{}'::jsonb,
  --  ex: { "pubmed_total":41, "pubmed_rct":9, "pubmed_meta":1,
  --        "pubmed_systematic":2, "ct_total":9, "ct_with_results":3,
  --        "europepmc_hits":55, "openalex_cited":1200, "openfda_events":4 }

  created_at          timestamptz not null default now(),
  unique (ingredient_id, captured_at, methodology_version)
);

create index if not exists idx_score_history_ing_date
  on public.score_history(ingredient_id, captured_at desc);

-- ---------------------------------------------------------------------
-- 3) ÉTAT COURANT  (lecture rapide pour le front-end)
--    Mis à jour par le puller après chaque capture.
--    Règle Alcyone : MOMENTUM seulement si >= 2 observations réelles,
--    sinon 'Baseline'. On NE FABRIQUE JAMAIS de variation.
-- ---------------------------------------------------------------------
create table if not exists public.score_meta (
  ingredient_id     uuid primary key references public.ingredients(id) on delete cascade,
  credibility_score numeric(5,2),
  confidence_level  text,
  trend_30d         numeric(6,2),          -- delta vs ~30 j (null tant que < 2 snapshots)
  trend_label       text default 'Baseline', -- 'Baseline' | 'Up' | 'Down' | 'Stable'
  observations      int default 0,
  last_captured_at  date,
  updated_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4) JOURNAL DES COLLECTES  (santé du cron / fraîcheur des données)
-- ---------------------------------------------------------------------
create table if not exists public.ingestion_runs (
  id                   bigint generated always as identity primary key,
  run_at               timestamptz not null default now(),
  source               text,                -- 'pubmed'|'clinicaltrials'|'europepmc'|...
  ingredients_processed int default 0,
  errors               int default 0,
  status               text default 'ok',   -- 'ok' | 'partial' | 'failed'
  notes                text
);

create index if not exists idx_ingestion_runs_date on public.ingestion_runs(run_at desc);

-- ---------------------------------------------------------------------
-- 5) SÉCURITÉ (RLS)
--    Lecture publique sur le catalogue et les scores (site public).
--    Aucune écriture publique : le puller écrit via la service-role key
--    (stockée côté GitHub Actions / Supabase secrets — jamais exposée),
--    qui contourne la RLS.
-- ---------------------------------------------------------------------
alter table public.ingredients     enable row level security;
alter table public.score_history   enable row level security;
alter table public.score_meta      enable row level security;
alter table public.ingestion_runs  enable row level security;

drop policy if exists "Public read ingredients"   on public.ingredients;
drop policy if exists "Public read score_history"  on public.score_history;
drop policy if exists "Public read score_meta"     on public.score_meta;

create policy "Public read ingredients"  on public.ingredients
  for select to anon, authenticated using (true);
create policy "Public read score_history" on public.score_history
  for select to anon, authenticated using (true);
create policy "Public read score_meta"    on public.score_meta
  for select to anon, authenticated using (true);

-- ingestion_runs : pas de lecture publique (interne). Rien de plus = tout est bloqué.

-- =====================================================================
--  FIN INSTALL 01. Lance ensuite INSTALL 02 (seed des ingrédients).
-- =====================================================================

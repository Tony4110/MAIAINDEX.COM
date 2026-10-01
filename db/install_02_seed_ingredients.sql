-- =====================================================================
--  MAIA — Longevity Credibility Index
--  INSTALL 02 / SEED INGREDIENTS  ·  v1.0  ·  2026-10-01
--  À lancer APRÈS INSTALL 01. Idempotent (ON CONFLICT DO NOTHING).
--  ~100 interventions classées en 13 catégories.
--  evidence_maturity_seed : 'strong' | 'emerging' | 'preclinical'
--  (indicatif au départ — le vrai score viendra des pullers)
-- =====================================================================

insert into public.ingredients
  (slug, name, category, synonyms, mechanism, evidence_maturity_seed, is_prescription, is_lifestyle)
values
-- 1) NAD+ boosters & precursors
('nmn','NMN','NAD+ boosters',ARRAY['nicotinamide mononucleotide','beta-NMN'],'Direct NAD+ precursor, raises cellular NAD+','emerging',false,false),
('nr','NR','NAD+ boosters',ARRAY['nicotinamide riboside','Niagen'],'NAD+ precursor, well absorbed','emerging',false,false),
('nad-direct','NAD+ (direct)','NAD+ boosters',ARRAY['liposomal NAD','IV NAD'],'Supplies the coenzyme directly','preclinical',false,false),
('niacin','Niacin','NAD+ boosters',ARRAY['nicotinic acid','vitamin B3'],'NAD+ precursor and lipid modifier','strong',false,false),
('nicotinamide','Nicotinamide','NAD+ boosters',ARRAY['niacinamide'],'NAD+ precursor, studied in dermatology','strong',false,false),
('nadh','NADH','NAD+ boosters',ARRAY['reduced NAD'],'Reduced electron-carrier form','preclinical',false,false),
('apigenin','Apigenin','NAD+ boosters',ARRAY['flavonoid'],'CD38 inhibitor, slows NAD+ degradation','preclinical',false,false),
-- 2) Senolytics
('fisetin','Fisetin','Senolytics',ARRAY['flavonol'],'Clears senescent cells in models','preclinical',false,false),
('quercetin','Quercetin','Senolytics',ARRAY['flavonoid'],'Senolytic, anti-inflammatory','emerging',false,false),
('dasatinib','Dasatinib','Senolytics',ARRAY['Sprycel'],'Tyrosine-kinase inhibitor, senolytic with quercetin','preclinical',true,false),
('navitoclax','Navitoclax','Senolytics',ARRAY['ABT-263'],'Bcl-2/Bcl-xL inhibitor, apoptosis of senescent cells','preclinical',true,false),
('piperlongumine','Piperlongumine','Senolytics',ARRAY['long pepper alkaloid'],'Senolytic, pro-oxidant in senescent cells','preclinical',false,false),
('procyanidin-c1','Procyanidin C1','Senolytics',ARRAY['PCC1','grape seed'],'Senolytic and senomorphic','preclinical',false,false),
-- 3) mTOR / AMPK / autophagy
('rapamycin','Rapamycin','mTOR / autophagy',ARRAY['sirolimus','Rapamune'],'mTOR inhibitor, flagship longevity candidate','emerging',true,false),
('spermidine','Spermidine','mTOR / autophagy',ARRAY['wheat germ extract'],'Induces autophagy, observational mortality link','emerging',false,false),
('trehalose','Trehalose','mTOR / autophagy',ARRAY['disaccharide'],'mTOR-independent autophagy inducer','preclinical',false,false),
('lithium-low-dose','Lithium (low-dose)','mTOR / autophagy',ARRAY['lithium orotate'],'GSK-3b inhibition, autophagy','preclinical',false,false),
('sulforaphane','Sulforaphane','mTOR / autophagy',ARRAY['broccoli sprout extract'],'Nrf2 activator, autophagy, detox enzymes','emerging',false,false),
('gynostemma','Gynostemma','mTOR / autophagy',ARRAY['jiaogulan'],'AMPK activation','preclinical',false,false),
-- 4) Polyphenols / antioxidant / anti-inflammatory
('resveratrol','Resveratrol','Polyphenols',ARRAY['trans-resveratrol'],'Sirtuin activator (debated), antioxidant','emerging',false,false),
('pterostilbene','Pterostilbene','Polyphenols',ARRAY['resveratrol analog'],'More bioavailable sirtuin/antioxidant','emerging',false,false),
('curcumin','Curcumin','Polyphenols',ARRAY['turmeric','Meriva','Theracurmin'],'Anti-inflammatory (NF-kB), antioxidant','strong',false,false),
('egcg','EGCG','Polyphenols',ARRAY['green tea catechins'],'Antioxidant, AMPK, metabolic','emerging',false,false),
('astaxanthin','Astaxanthin','Polyphenols',ARRAY['AstaReal','BioAstin'],'Potent carotenoid antioxidant','emerging',false,false),
('pycnogenol','Pycnogenol','Polyphenols',ARRAY['pine bark extract'],'Vascular antioxidant, endothelial','emerging',false,false),
('luteolin','Luteolin','Polyphenols',ARRAY['flavonoid'],'Anti-inflammatory, senomorphic','preclinical',false,false),
('ergothioneine','Ergothioneine','Polyphenols',ARRAY['EGT','longevity vitamin'],'Cytoprotective antioxidant, mitochondrial','preclinical',false,false),
('glutathione','Glutathione','Polyphenols',ARRAY['reduced L-glutathione','liposomal'],'Master endogenous antioxidant','emerging',false,false),
('nac','NAC','Polyphenols',ARRAY['N-acetylcysteine'],'Glutathione precursor, anti-inflammatory','strong',false,false),
('alpha-lipoic-acid','Alpha-lipoic acid','Polyphenols',ARRAY['ALA','R-ALA'],'Mitochondrial antioxidant, glucose handling','emerging',false,false),
('hesperidin','Hesperidin','Polyphenols',ARRAY['citrus flavonoid'],'Vascular, anti-inflammatory','preclinical',false,false),
-- 5) Cardiometabolic / glucose
('metformin','Metformin','Cardiometabolic',ARRAY['Glucophage'],'AMPK activation, glucose lowering, TAME target','emerging',true,false),
('berberine','Berberine','Cardiometabolic',ARRAY['natures metformin'],'AMPK activation, glucose and lipid lowering','strong',false,false),
('omega-3','Omega-3','Cardiometabolic',ARRAY['fish oil','EPA','DHA','krill','algae oil'],'Anti-inflammatory, cardiovascular, membrane','strong',false,false),
('citrus-bergamot','Citrus bergamot','Cardiometabolic',ARRAY['bergamot polyphenols'],'Lipid and cholesterol modulation','emerging',false,false),
('red-yeast-rice','Red yeast rice','Cardiometabolic',ARRAY['monacolin K'],'Natural statin-like LDL lowering','strong',false,false),
('nattokinase','Nattokinase','Cardiometabolic',ARRAY['fibrinolytic enzyme'],'Fibrinolysis, blood-flow support','emerging',false,false),
('acarbose','Acarbose','Cardiometabolic',ARRAY['Precose'],'Alpha-glucosidase inhibitor, lifespan up in mice','preclinical',true,false),
('inositol','Inositol','Cardiometabolic',ARRAY['myo-inositol','D-chiro'],'Insulin sensitivity','emerging',false,false),
('psyllium-beta-glucan','Psyllium / beta-glucan','Cardiometabolic',ARRAY['soluble fiber'],'LDL and glucose, satiety, microbiome','strong',false,false),
('plant-sterols','Plant sterols','Cardiometabolic',ARRAY['phytosterols'],'Cholesterol absorption blockade','strong',false,false),
-- 6) Mitochondrial support
('coq10','CoQ10','Mitochondrial',ARRAY['ubiquinone','ubiquinol','Kaneka'],'Electron transport, cardiac energetics','strong',false,false),
('pqq','PQQ','Mitochondrial',ARRAY['pyrroloquinoline quinone'],'Mitochondrial biogenesis','emerging',false,false),
('urolithin-a','Urolithin A','Mitochondrial',ARRAY['Mitopure'],'Mitophagy inducer, muscle endurance','emerging',false,false),
('acetyl-l-carnitine','Acetyl-L-carnitine','Mitochondrial',ARRAY['ALCAR'],'Fatty-acid transport, neuro-energetics','emerging',false,false),
('creatine','Creatine','Mitochondrial',ARRAY['creatine monohydrate'],'Cellular energy buffer, muscle and cognition','strong',false,false),
('mitoq','MitoQ','Mitochondrial',ARRAY['mitoquinol mesylate'],'Mitochondria-targeted CoQ10 antioxidant','emerging',false,false),
('shilajit','Shilajit','Mitochondrial',ARRAY['fulvic acid','mumijo'],'Mitochondrial/CoQ10 support, minerals','preclinical',false,false),
('d-ribose','D-ribose','Mitochondrial',ARRAY['pentose sugar'],'ATP-substrate replenishment','preclinical',false,false),
-- 7) Foundational vitamins & minerals
('vitamin-d3','Vitamin D3','Vitamins & minerals',ARRAY['cholecalciferol'],'Hormone-like, immune, bone, mortality signal','strong',false,false),
('vitamin-k2','Vitamin K2','Vitamins & minerals',ARRAY['MK-7','MenaQ7'],'Directs calcium to bone, away from arteries','emerging',false,false),
('magnesium','Magnesium','Vitamins & minerals',ARRAY['glycinate','threonate','malate'],'Enzyme cofactor, metabolic, sleep, cardio','strong',false,false),
('zinc','Zinc','Vitamins & minerals',ARRAY['picolinate','bisglycinate'],'Immune, antioxidant enzymes','strong',false,false),
('vitamin-b12','Vitamin B12','Vitamins & minerals',ARRAY['methylcobalamin'],'Methylation, neuro, hematologic','strong',false,false),
('methylfolate','Methylfolate','Vitamins & minerals',ARRAY['5-MTHF','folate'],'One-carbon metabolism, homocysteine','strong',false,false),
('vitamin-c','Vitamin C','Vitamins & minerals',ARRAY['ascorbic acid','liposomal'],'Antioxidant, collagen cofactor','strong',false,false),
('vitamin-e','Vitamin E','Vitamins & minerals',ARRAY['tocotrienols','tocopherols'],'Lipid antioxidant','emerging',false,false),
('selenium','Selenium','Vitamins & minerals',ARRAY['selenomethionine'],'Glutathione-peroxidase cofactor, thyroid','strong',false,false),
('iodine','Iodine','Vitamins & minerals',ARRAY['potassium iodide','kelp'],'Thyroid hormone synthesis','strong',false,false),
('boron','Boron','Vitamins & minerals',ARRAY['trace mineral'],'Hormone and bone metabolism','preclinical',false,false),
-- 8) Longevity / regenerative peptides
('bpc-157','BPC-157','Peptides',ARRAY['body protection compound'],'Angiogenesis, gut and tissue repair','preclinical',false,false),
('tb-500','TB-500','Peptides',ARRAY['thymosin beta-4'],'Actin regulation, tissue repair','preclinical',false,false),
('epitalon','Epitalon','Peptides',ARRAY['epithalon'],'Pineal / telomerase stimulation claims','preclinical',false,false),
('thymosin-alpha-1','Thymosin alpha-1','Peptides',ARRAY['Zadaxin'],'Immune modulation, immunosenescence','emerging',true,false),
('ghk-cu','GHK-Cu','Peptides',ARRAY['copper tripeptide'],'Skin remodeling, gene-expression reset','preclinical',false,false),
('mots-c','MOTS-c','Peptides',ARRAY['mitochondrial-derived peptide'],'Metabolic exercise-mimetic signaling','preclinical',false,false),
('cjc1295-ipamorelin','CJC-1295 / Ipamorelin','Peptides',ARRAY['GHRH','GH secretagogue'],'Stimulate endogenous growth hormone','preclinical',true,false),
('humanin','Humanin','Peptides',ARRAY['mitochondrial peptide'],'Cytoprotective, metabolic','preclinical',false,false),
-- 9) Amino acids & metabolic building blocks
('glycine','Glycine','Amino acids',ARRAY['amino acid'],'Collagen and glutathione synthesis, sleep','emerging',false,false),
('glynac','GlyNAC','Amino acids',ARRAY['glycine + NAC'],'Restores glutathione, Baylor aging trials','emerging',false,false),
('taurine','Taurine','Amino acids',ARRAY['amino sulfonic acid'],'Multi-system, mouse lifespan + human observational','preclinical',false,false),
('tmg','TMG','Amino acids',ARRAY['betaine','trimethylglycine'],'Methyl donor, homocysteine buffer','emerging',false,false),
('l-citrulline','L-citrulline','Amino acids',ARRAY['citrulline'],'Nitric-oxide, vascular, blood flow','emerging',false,false),
('l-glutamine','L-glutamine','Amino acids',ARRAY['glutamine'],'Gut lining, immune fuel','emerging',false,false),
('carnosine-beta-alanine','Carnosine / beta-alanine','Amino acids',ARRAY['dipeptide'],'Anti-glycation, muscle buffering','emerging',false,false),
('l-theanine','L-theanine','Amino acids',ARRAY['green tea amino'],'Calm focus, stress and sleep','emerging',false,false),
-- 10) Structural — skin / joint / connective
('collagen-peptides','Collagen peptides','Structural',ARRAY['hydrolyzed collagen','Vital Proteins'],'Skin elasticity, joint and bone matrix','emerging',false,false),
('hyaluronic-acid','Hyaluronic acid','Structural',ARRAY['HA','sodium hyaluronate'],'Skin and joint hydration','emerging',false,false),
('glucosamine-chondroitin','Glucosamine + chondroitin','Structural',ARRAY['combo'],'Cartilage support, observational mortality signal','strong',false,false),
('msm','MSM','Structural',ARRAY['methylsulfonylmethane'],'Sulfur donor, joint and anti-inflammatory','emerging',false,false),
('silica-biotin','Silica / biotin','Structural',ARRAY['silicon','vitamin B7'],'Hair, skin, nail connective tissue','preclinical',false,false),
-- 11) Adaptogens / hormonal / herbal
('ashwagandha','Ashwagandha','Adaptogens & hormonal',ARRAY['withania','KSM-66','Sensoril'],'Cortisol and stress modulation','emerging',false,false),
('rhodiola','Rhodiola','Adaptogens & hormonal',ARRAY['rhodiola rosea'],'Stress resilience, fatigue','emerging',false,false),
('panax-ginseng','Panax ginseng','Adaptogens & hormonal',ARRAY['korean ginseng','red ginseng'],'Energy, immune, metabolic','emerging',false,false),
('cycloastragenol-ta65','Cycloastragenol / TA-65','Adaptogens & hormonal',ARRAY['astragalus extract'],'Telomerase activation claims','preclinical',false,false),
('melatonin','Melatonin','Adaptogens & hormonal',ARRAY['hormone'],'Circadian, antioxidant, mitochondrial','strong',false,false),
('dhea','DHEA','Adaptogens & hormonal',ARRAY['dehydroepiandrosterone'],'Hormone precursor, declines with age','emerging',false,false),
('reishi','Reishi','Adaptogens & hormonal',ARRAY['ganoderma lucidum'],'Immune modulation','preclinical',false,false),
('lions-mane','Lions mane','Adaptogens & hormonal',ARRAY['hericium erinaceus'],'NGF / neurotrophic, cognition','emerging',false,false),
-- 12) Gut / microbiome
('probiotics-multi','Multi-strain probiotics','Gut & microbiome',ARRAY['probiotics'],'Microbiome balance, immune and gut','emerging',false,false),
('akkermansia','Akkermansia muciniphila','Gut & microbiome',ARRAY['Pendulum'],'Gut-barrier and metabolic health','emerging',false,false),
-- 13) Lifestyle & clinical interventions (scored protocols)
('caloric-restriction','Caloric restriction','Lifestyle & protocols',ARRAY['CR'],'Reduced mTOR/IGF-1, canonical lifespan lever','emerging',false,true),
('time-restricted-eating','Time-restricted eating','Lifestyle & protocols',ARRAY['intermittent fasting','TRE'],'Autophagy, metabolic switching','emerging',false,true),
('zone-2-cardio','Zone 2 cardio','Lifestyle & protocols',ARRAY['aerobic base training'],'Mitochondrial density, VO2max','strong',false,true),
('resistance-training','Resistance training','Lifestyle & protocols',ARRAY['strength training'],'Muscle mass and strength, mortality predictor','strong',false,true),
('sauna-heat','Sauna / heat','Lifestyle & protocols',ARRAY['heat-shock therapy'],'Heat-shock proteins, cardiovascular mortality down','emerging',false,true),
('cold-exposure','Cold exposure','Lifestyle & protocols',ARRAY['cold plunge','CWI'],'Brown fat, hormesis, mood','preclinical',false,true),
('sleep-optimization','Sleep optimization','Lifestyle & protocols',ARRAY['circadian hygiene'],'Glymphatic clearance, metabolic and immune','strong',false,true),
('hbot','HBOT','Lifestyle & protocols',ARRAY['hyperbaric oxygen'],'Hypoxia paradox, telomere and senescence signal','preclinical',false,true),
('plasma-exchange','Therapeutic plasma exchange','Lifestyle & protocols',ARRAY['TPE','plasma dilution'],'Removes pro-aging plasma factors','preclinical',false,true)
on conflict (slug) do nothing;

-- =====================================================================
--  FIN INSTALL 02. Vérif rapide :
--    select category, count(*) from public.ingredients group by category order by 1;
-- =====================================================================

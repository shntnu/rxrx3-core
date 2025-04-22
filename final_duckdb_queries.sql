-- Final DuckDB queries for RxRx3-core metadata analysis
-- Usage: duckdb -c "QUERY" or run in DuckDB shell

-- 1. Summary of dataset contents
SELECT 
  'RxRx3-core Dataset' AS dataset_name,
  COUNT(*) AS total_wells,
  COUNT(DISTINCT experiment_name) AS experiments,
  COUNT(DISTINCT gene) AS unique_genes,
  COUNT(DISTINCT treatment) AS unique_treatments,
  SUM(CASE WHEN perturbation_type = 'CRISPR' THEN 1 ELSE 0 END) AS crispr_wells,
  SUM(CASE WHEN perturbation_type = 'COMPOUND' THEN 1 ELSE 0 END) AS compound_wells,
  COUNT(DISTINCT plate) AS unique_plates
FROM read_csv_auto('metadata_rxrx3_core.csv');

-- 2. Experiment types with detailed statistics
WITH raw_stats AS (
  SELECT
    experiment_name,
    COUNT(*) AS well_count,
    COUNT(DISTINCT gene) AS gene_count,
    COUNT(DISTINCT treatment) AS treatment_count,
    SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) AS gene_controls,
    SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS treatment_controls,
    SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS crispr_controls,
    COUNT(DISTINCT concentration) AS concentration_levels
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  GROUP BY experiment_name
)
SELECT
  CASE WHEN experiment_name LIKE 'gene-%' THEN 'GENE' WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND' ELSE 'OTHER' END AS experiment_type,
  COUNT(*) AS experiment_count,
  SUM(well_count) AS total_wells,
  ROUND(AVG(well_count), 1) AS avg_wells_per_experiment,
  MAX(well_count) AS max_wells,
  MIN(well_count) AS min_wells,
  ROUND(AVG(gene_count), 1) AS avg_genes_per_experiment,
  ROUND(AVG(treatment_count), 1) AS avg_treatments_per_experiment,
  ROUND(AVG(concentration_levels), 1) AS avg_concentration_levels
FROM raw_stats
GROUP BY experiment_type
ORDER BY total_wells DESC;

-- 3. Concentration distribution with percentages (for COMPOUND only)
WITH total_compounds AS (
  SELECT COUNT(*) AS total_count 
  FROM read_csv_auto('metadata_rxrx3_core.csv') 
  WHERE perturbation_type = 'COMPOUND'
)
SELECT
  concentration,
  COUNT(*) AS wells,
  ROUND(COUNT(*) * 100.0 / total_count, 2) AS percentage,
  COUNT(DISTINCT treatment) AS unique_compounds,
  COUNT(DISTINCT experiment_name) AS experiments,
  COUNT(DISTINCT plate) AS unique_plates
FROM read_csv_auto('metadata_rxrx3_core.csv'), total_compounds
WHERE perturbation_type = 'COMPOUND' AND concentration IS NOT NULL
GROUP BY concentration, total_count
ORDER BY concentration;

-- 4. Control distribution analysis
SELECT
  experiment_name,
  SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) AS gene_controls,
  SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS empty_controls,
  SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS crispr_controls,
  COUNT(*) AS total_wells,
  ROUND(SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS gene_control_pct,
  ROUND(SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS empty_control_pct,
  ROUND(SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS crispr_control_pct
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY experiment_name
ORDER BY total_wells DESC
LIMIT 10;

-- 5. SMILES analysis for compounds
WITH smiles_data AS (
  SELECT
    treatment,
    COUNT(*) AS occurrences,
    SMILES IS NOT NULL AND SMILES <> '' AS has_smiles,
    COUNT(DISTINCT concentration) AS concentration_levels,
    COUNT(DISTINCT experiment_name) AS experiments
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE perturbation_type = 'COMPOUND' AND treatment <> 'EMPTY_control' AND treatment <> 'CRISPR_control'
  GROUP BY treatment, has_smiles
)
SELECT
  has_smiles,
  COUNT(*) AS compound_count,
  SUM(occurrences) AS total_wells,
  ROUND(AVG(concentration_levels), 2) AS avg_concentration_levels,
  ROUND(AVG(experiments), 2) AS avg_experiments_per_compound,
  MIN(occurrences) AS min_occurrences,
  MAX(occurrences) AS max_occurrences,
  ROUND(AVG(occurrences), 2) AS avg_occurrences
FROM smiles_data
GROUP BY has_smiles
ORDER BY has_smiles;

-- 6. Top CRISPR genes (excluding controls) with experiment coverage
WITH gene_exp_data AS (
  SELECT
    gene,
    experiment_name
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE perturbation_type = 'CRISPR' AND gene <> 'EMPTY_control'
  GROUP BY gene, experiment_name
)
SELECT
  g.gene,
  COUNT(*) AS well_count,
  COUNT(DISTINCT experiment_name) AS experiments,
  COUNT(DISTINCT e.experiment_name) AS gene_experiments,
  ROUND(COUNT(DISTINCT e.experiment_name) * 100.0 / (SELECT COUNT(DISTINCT experiment_name) FROM read_csv_auto('metadata_rxrx3_core.csv') WHERE experiment_name LIKE 'gene-%'), 2) AS gene_experiment_coverage_pct
FROM read_csv_auto('metadata_rxrx3_core.csv') g
LEFT JOIN gene_exp_data e ON g.gene = e.gene
WHERE g.perturbation_type = 'CRISPR' AND g.gene <> 'EMPTY_control'
GROUP BY g.gene
ORDER BY well_count DESC
LIMIT 20;

-- 7. Address (well position) analysis
SELECT
  address,
  COUNT(*) AS wells,
  COUNT(DISTINCT plate) AS plates,
  COUNT(DISTINCT experiment_name) AS experiments,
  SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS control_wells,
  ROUND(SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS control_pct
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY address
ORDER BY wells DESC
LIMIT 20;

-- 8. Detailed plate statistics with control percentages
SELECT
  plate,
  COUNT(*) AS wells,
  COUNT(DISTINCT experiment_name) AS experiments,
  SUM(CASE WHEN perturbation_type = 'CRISPR' THEN 1 ELSE 0 END) AS crispr_wells,
  SUM(CASE WHEN perturbation_type = 'COMPOUND' THEN 1 ELSE 0 END) AS compound_wells,
  SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' OR treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS control_wells,
  ROUND(SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' OR treatment = 'CRISPR_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS control_pct
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY plate
ORDER BY wells DESC
LIMIT 10;

-- 9. Experiment size distribution
WITH experiment_sizes AS (
  SELECT
    experiment_name,
    COUNT(*) AS well_count
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  GROUP BY experiment_name
),
size_buckets AS (
  SELECT
    experiment_name,
    well_count,
    CASE
      WHEN well_count < 100 THEN 'XS (<100)'
      WHEN well_count < 500 THEN 'S (100-499)'
      WHEN well_count < 1000 THEN 'M (500-999)'
      WHEN well_count < 5000 THEN 'L (1000-4999)'
      WHEN well_count < 10000 THEN 'XL (5000-9999)'
      ELSE 'XXL (10000+)'
    END AS size_category
  FROM experiment_sizes
)
SELECT
  size_category,
  COUNT(*) AS experiment_count,
  SUM(well_count) AS total_wells,
  ROUND(AVG(well_count), 1) AS avg_wells,
  MIN(well_count) AS min_wells,
  MAX(well_count) AS max_wells
FROM size_buckets
GROUP BY size_category
ORDER BY MIN(well_count);

-- 10. Gene-Treatment correlation analysis
-- Find genes and treatments that frequently appear together
WITH gene_treatment_combo AS (
  SELECT
    gene,
    treatment,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT experiment_name) AS experiments
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE gene <> '' AND treatment <> '' 
    AND gene <> 'EMPTY_control' AND treatment <> 'EMPTY_control' 
    AND treatment <> 'CRISPR_control'
  GROUP BY gene, treatment
  HAVING COUNT(*) > 5 -- filter to significant co-occurrences
),
gene_totals AS (
  SELECT
    gene,
    COUNT(*) AS total_gene_occurrences
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE gene <> '' AND gene <> 'EMPTY_control'
  GROUP BY gene
),
treatment_totals AS (
  SELECT
    treatment,
    COUNT(*) AS total_treatment_occurrences
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE treatment <> '' AND treatment <> 'EMPTY_control' AND treatment <> 'CRISPR_control'
  GROUP BY treatment
)
SELECT
  gt.gene,
  gt.treatment,
  gt.occurrences,
  gt.experiments,
  g.total_gene_occurrences,
  t.total_treatment_occurrences,
  ROUND(gt.occurrences * 100.0 / g.total_gene_occurrences, 2) AS pct_of_gene,
  ROUND(gt.occurrences * 100.0 / t.total_treatment_occurrences, 2) AS pct_of_treatment
FROM gene_treatment_combo gt
JOIN gene_totals g ON gt.gene = g.gene
JOIN treatment_totals t ON gt.treatment = t.treatment
ORDER BY gt.occurrences DESC
LIMIT 20;
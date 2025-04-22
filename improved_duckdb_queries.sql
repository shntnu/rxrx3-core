-- Improved DuckDB queries for RxRx3-core metadata analysis
-- Usage: duckdb -c "QUERY" or run in DuckDB shell

-- 1. Comprehensive dataset statistics
SELECT 
  COUNT(*) AS total_records,
  COUNT(DISTINCT gene) AS unique_genes,
  COUNT(DISTINCT treatment) AS unique_treatments,
  COUNT(DISTINCT experiment_name) AS unique_experiments,
  COUNT(DISTINCT plate) AS unique_plates,
  SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) AS gene_controls,
  SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS treatment_controls,
  SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS crispr_controls
FROM read_csv_auto('metadata_rxrx3_core.csv');

-- 2. Distribution of empty/non-empty gene and treatment fields
SELECT
  gene IS NOT NULL AND gene <> '' AS has_gene,
  treatment IS NOT NULL AND treatment <> '' AS has_treatment,
  perturbation_type,
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 3. Experiment type analysis (pattern-based)
SELECT
  CASE 
    WHEN experiment_name LIKE 'gene-%' THEN 'GENE'
    WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND'
    ELSE 'OTHER'
  END AS experiment_type,
  COUNT(DISTINCT experiment_name) AS experiment_count,
  COUNT(*) AS record_count,
  AVG(COUNT(*)) OVER (PARTITION BY CASE WHEN experiment_name LIKE 'gene-%' THEN 'GENE' WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND' ELSE 'OTHER' END) AS avg_records_per_experiment
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY experiment_type;

-- 4. Detailed concentration analysis for compounds
SELECT
  concentration,
  COUNT(*) AS wells,
  COUNT(DISTINCT treatment) AS unique_compounds,
  COUNT(DISTINCT experiment_name) AS experiments
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'COMPOUND' AND concentration IS NOT NULL
GROUP BY concentration
ORDER BY concentration;

-- 5. Treatment analysis - find treatments used in both CRISPR and COMPOUND experiments
SELECT
  treatment,
  COUNT(DISTINCT experiment_name) AS experiments,
  SUM(CASE WHEN perturbation_type = 'CRISPR' THEN 1 ELSE 0 END) > 0 AS used_in_crispr,
  SUM(CASE WHEN perturbation_type = 'COMPOUND' THEN 1 ELSE 0 END) > 0 AS used_in_compound,
  COUNT(*) AS total_wells
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE treatment NOT IN ('EMPTY_control', 'CRISPR_control') 
  AND treatment <> ''
GROUP BY treatment
HAVING SUM(CASE WHEN perturbation_type = 'CRISPR' THEN 1 ELSE 0 END) > 0 
   AND SUM(CASE WHEN perturbation_type = 'COMPOUND' THEN 1 ELSE 0 END) > 0
ORDER BY total_wells DESC;

-- 6. Experiment-gene-treatment relationships
WITH gene_counts AS (
  SELECT 
    experiment_name,
    COUNT(DISTINCT gene) AS gene_count
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE gene <> '' AND gene <> 'EMPTY_control'
  GROUP BY experiment_name
),
treatment_counts AS (
  SELECT 
    experiment_name,
    COUNT(DISTINCT treatment) AS treatment_count
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE treatment <> '' AND treatment NOT IN ('EMPTY_control', 'CRISPR_control')
  GROUP BY experiment_name
)
SELECT 
  e.experiment_name,
  COUNT(*) AS well_count,
  COALESCE(g.gene_count, 0) AS unique_genes,
  COALESCE(t.treatment_count, 0) AS unique_treatments,
  CASE 
    WHEN e.experiment_name LIKE 'gene-%' THEN 'GENE'
    WHEN e.experiment_name LIKE 'compound-%' THEN 'COMPOUND'
    ELSE 'OTHER'
  END AS exp_type
FROM read_csv_auto('metadata_rxrx3_core.csv') e
LEFT JOIN gene_counts g ON e.experiment_name = g.experiment_name
LEFT JOIN treatment_counts t ON e.experiment_name = t.experiment_name
GROUP BY e.experiment_name, g.gene_count, t.treatment_count
ORDER BY well_count DESC;

-- 7. Plate statistics - wells per plate and distribution
SELECT
  plate,
  COUNT(*) AS wells,
  COUNT(DISTINCT address) AS unique_addresses,
  COUNT(DISTINCT experiment_name) AS experiments,
  SUM(CASE WHEN perturbation_type = 'CRISPR' THEN 1 ELSE 0 END) AS crispr_wells,
  SUM(CASE WHEN perturbation_type = 'COMPOUND' THEN 1 ELSE 0 END) AS compound_wells
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY plate
ORDER BY wells DESC
LIMIT 20;

-- 8. SMILES presence analysis
SELECT
  perturbation_type,
  SMILES IS NOT NULL AND SMILES <> '' AS has_smiles,
  COUNT(*) AS count,
  COUNT(DISTINCT treatment) AS unique_treatments
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY perturbation_type, has_smiles
ORDER BY perturbation_type, has_smiles;

-- 9. Gene frequency in CRISPR experiments (excluding controls)
SELECT
  gene,
  COUNT(*) AS well_count,
  COUNT(DISTINCT experiment_name) AS experiment_count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv') 
    WHERE perturbation_type = 'CRISPR' AND gene <> 'EMPTY_control'), 2) AS percentage_of_non_control
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'CRISPR' AND gene <> 'EMPTY_control'
GROUP BY gene
ORDER BY well_count DESC
LIMIT 20;

-- 10. Advanced experiment type analysis
WITH experiment_stats AS (
  SELECT
    experiment_name,
    COUNT(*) AS well_count,
    COUNT(DISTINCT gene) AS gene_count,
    COUNT(DISTINCT treatment) AS treatment_count,
    SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) AS gene_controls,
    SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS treatment_controls,
    SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS crispr_controls,
    MIN(concentration) AS min_concentration,
    MAX(concentration) AS max_concentration,
    COUNT(DISTINCT concentration) AS concentration_count
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  GROUP BY experiment_name
)
SELECT
  experiment_name,
  well_count,
  gene_count,
  treatment_count,
  gene_controls,
  treatment_controls,
  crispr_controls,
  min_concentration,
  max_concentration,
  concentration_count,
  CASE
    WHEN experiment_name LIKE 'gene-%' THEN 'GENE'
    WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND'
    ELSE 'OTHER'
  END AS experiment_type,
  CASE
    WHEN gene_count > 1 AND treatment_count <= 1 THEN 'GENE_FOCUSED'
    WHEN gene_count <= 1 AND treatment_count > 1 THEN 'COMPOUND_FOCUSED'
    WHEN gene_count > 1 AND treatment_count > 1 THEN 'MIXED'
    ELSE 'CONTROL_ONLY'
  END AS content_type
FROM experiment_stats
ORDER BY well_count DESC
LIMIT 20;
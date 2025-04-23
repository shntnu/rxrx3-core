-- RxRx3-core Metadata Analysis Queries
-- Usage: duckdb -c "QUERY" metadata_rxrx3_core.csv
-- 
-- This file contains carefully crafted SQL queries for analyzing the RxRx3-core dataset metadata.
-- Each section contains a specific analysis with sample output as comments.
-- Run these queries using DuckDB (https://duckdb.org/) for fast local analysis.
--
-- Example: duckdb -c "SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv');"
--
-- Created using Claude Code: https://claude.ai/code

-- =============================================
-- 1. DATASET OVERVIEW
-- =============================================

-- 1.1 Basic dataset statistics
-- Shows total records, unique genes, treatments, experiments, and control counts
-- 
-- Example output:
-- ┌───────────────┬──────────────┬───────────────────┬────────────────────┬───────────────┬─────────────────┐
-- │ total_records │ unique_genes │ unique_treatments │ unique_experiments │ gene_controls │ crispr_controls │
-- │     int64     │    int64     │       int64       │       int64        │    int128     │     int128      │
-- ├───────────────┼──────────────┼───────────────────┼────────────────────┼───────────────┼─────────────────┤
-- │        222601 │          736 │              6108 │                180 │         25312 │           22062 │
-- └───────────────┴──────────────┴───────────────────┴────────────────────┴───────────────┴─────────────────┘
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

-- 1.2 Perturbation type distribution
-- Shows the breakdown between CRISPR and COMPOUND perturbations
--
-- Example output:
-- ┌───────────────────┬────────┬────────────┐
-- │ perturbation_type │ count  │ percentage │
-- │      varchar      │ int64  │   double   │
-- ├───────────────────┼────────┼────────────┤
-- │ CRISPR            │ 126900 │      57.01 │
-- │ COMPOUND          │  95701 │      42.99 │
-- └───────────────────┴────────┴────────────┘
SELECT 
  perturbation_type, 
  COUNT(*) AS count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv')), 2) AS percentage
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY perturbation_type
ORDER BY count DESC;

-- 1.3 Gene and treatment distribution
-- Shows the distribution of gene and treatment fields across perturbation types
--
-- Example output:
-- ┌──────────┬───────────────┬───────────────────┬────────┐
-- │ has_gene │ has_treatment │ perturbation_type │ count  │
-- │ boolean  │    boolean    │      varchar      │ int64  │
-- ├──────────┼───────────────┼───────────────────┼────────┤
-- │ false    │ true          │ COMPOUND          │  95701 │
-- │ true     │ true          │ CRISPR            │ 126900 │
-- └──────────┴───────────────┴───────────────────┴────────┘
SELECT
  gene IS NOT NULL AND gene <> '' AS has_gene,
  treatment IS NOT NULL AND treatment <> '' AS has_treatment,
  perturbation_type,
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- =============================================
-- 2. EXPERIMENT ANALYSIS
-- =============================================

-- 2.1 Experiment type analysis
-- Categorizes experiments by 'gene' or 'compound' and shows statistics for each type
--
-- Example output:
-- ┌─────────────────┬──────────────────┬────────────┬────────────────────────────┐
-- │ experiment_type │ experiment_count │ total_wells│ avg_records_per_experiment │
-- │     varchar     │      int64       │    int64   │           double           │
-- ├─────────────────┼──────────────────┼────────────┼────────────────────────────┤
-- │ GENE            │              176 │      126900│                      721.0 │
-- │ COMPOUND        │                4 │       95701│                    23925.2 │
-- └─────────────────┴──────────────────┴────────────┴────────────────────────────┘
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
  CASE 
    WHEN experiment_name LIKE 'gene-%' THEN 'GENE' 
    WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND' 
    ELSE 'OTHER'
  END AS experiment_type,
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

-- 2.2 Top experiments by size
-- Lists the largest experiments with their gene/treatment counts
--
-- Example output:
-- ┌─────────────────┬────────────┬────────────┬─────────────────┬─────────────────┐
-- │ experiment_name │ well_count │ gene_count │ treatment_count │ experiment_type │
-- │     varchar     │   int64    │   int64    │      int64      │     varchar     │
-- ├─────────────────┼────────────┼────────────┼─────────────────┼─────────────────┤
-- │ compound-003    │      39664 │          0 │             877 │ COMPOUND        │
-- │ compound-001    │      28231 │          0 │             522 │ COMPOUND        │
-- │ compound-004    │      21125 │          0 │             290 │ COMPOUND        │
-- │ compound-002    │       6681 │          0 │              92 │ COMPOUND        │
-- │ gene-132        │       1304 │         26 │             130 │ GENE            │
-- └─────────────────┴────────────┴────────────┴─────────────────┴─────────────────┘
WITH experiment_stats AS (
  SELECT
    experiment_name,
    COUNT(*) AS well_count,
    COUNT(DISTINCT gene) AS gene_count,
    COUNT(DISTINCT treatment) AS treatment_count
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  GROUP BY experiment_name
)
SELECT
  experiment_name,
  well_count,
  gene_count,
  treatment_count,
  CASE
    WHEN experiment_name LIKE 'gene-%' THEN 'GENE'
    WHEN experiment_name LIKE 'compound-%' THEN 'COMPOUND'
    ELSE 'OTHER'
  END AS experiment_type
FROM experiment_stats
ORDER BY well_count DESC
LIMIT 10;

-- 2.3 Experiment size distribution by category
-- Groups experiments by size categories and shows distribution
-- 
-- Example output:
-- ┌────────────────┬──────────────────┬─────────────┬───────────┬───────────┬───────────┐
-- │ size_category  │ experiment_count │ total_wells │ avg_wells │ min_wells │ max_wells │
-- │    varchar     │      int64       │   int128    │  double   │   int64   │   int64   │
-- ├────────────────┼──────────────────┼─────────────┼───────────┼───────────┼───────────┤
-- │ S (100-499)    │               14 │        6402 │     457.3 │       342 │       496 │
-- │ M (500-999)    │              153 │      110308 │     721.0 │       501 │       993 │
-- │ L (1000-4999)  │                9 │       10190 │    1132.2 │      1043 │      1304 │
-- │ XL (5000-9999) │                1 │        6681 │    6681.0 │      6681 │      6681 │
-- │ XXL (10000+)   │                3 │       89020 │   29673.3 │     21125 │     39664 │
-- └────────────────┴──────────────────┴─────────────┴───────────┴───────────┴───────────┘
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

-- =============================================
-- 3. CRISPR PERTURBATION ANALYSIS
-- =============================================

-- 3.1 Top CRISPR genes
-- Lists the most frequently occurring genes in CRISPR experiments (excluding controls)
--
-- Example output:
-- ┌───────┬───────┐
-- │ gene  │ count │
-- │varchar│ int64 │
-- ├───────┼───────┤
-- │ PLK1  │  9471 │
-- │ MTOR  │  9456 │
-- │ SRC   │  1672 │
-- │ EIF3H │  1669 │
-- │ HCK   │  1667 │
-- └───────┴───────┘
SELECT
  gene,
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'CRISPR' AND gene <> 'EMPTY_control'
GROUP BY gene
ORDER BY count DESC
LIMIT 10;

-- 3.2 Gene distribution across experiments
-- Shows how genes are distributed across experiments with coverage percentage
--
-- Example output:
-- ┌───────┬───────────┬─────────────┬───────────────────┬────────────────────────────┐
-- │ gene  │ well_count│ experiments │ gene_experiments  │ gene_experiment_coverage_% │
-- │varchar│   int64   │    int64    │       int64       │           double           │
-- ├───────┼───────────┼─────────────┼───────────────────┼────────────────────────────┤
-- │ PLK1  │      9471 │         153 │               153 │                      86.93 │
-- │ MTOR  │      9456 │         152 │               152 │                      86.36 │
-- │ SRC   │      1672 │          24 │                24 │                      13.64 │
-- └───────┴───────────┴─────────────┴───────────────────┴────────────────────────────┘
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
  COUNT(DISTINCT g.experiment_name) AS experiments,
  COUNT(DISTINCT e.experiment_name) AS gene_experiments,
  ROUND(COUNT(DISTINCT e.experiment_name) * 100.0 / (SELECT COUNT(DISTINCT experiment_name) FROM read_csv_auto('metadata_rxrx3_core.csv') WHERE experiment_name LIKE 'gene-%'), 2) AS gene_experiment_coverage_pct
FROM read_csv_auto('metadata_rxrx3_core.csv') g
LEFT JOIN gene_exp_data e ON g.gene = e.gene
WHERE g.perturbation_type = 'CRISPR' AND g.gene <> 'EMPTY_control'
GROUP BY g.gene
ORDER BY well_count DESC
LIMIT 10;

-- =============================================
-- 4. COMPOUND PERTURBATION ANALYSIS
-- =============================================

-- 4.1 Concentration distribution
-- Shows distribution of compounds across different concentration levels
--
-- Example output:
-- ┌───────────────┬───────┬────────────┬──────────────────┬─────────────┐
-- │ concentration │ wells │ percentage │ unique_compounds │ experiments │
-- │    double     │ int64 │   double   │      int64       │    int64    │
-- ├───────────────┼───────┼────────────┼──────────────────┼─────────────┤
-- │        0.0025 │  6732 │       7.03 │             1669 │           4 │
-- │          0.01 │  6733 │       7.04 │             1670 │           4 │
-- │         0.025 │  6727 │       7.03 │             1668 │           4 │
-- │           0.1 │  6727 │       7.03 │             1669 │           4 │
-- │          0.25 │ 11527 │      12.04 │             1673 │           4 │
-- │           1.0 │  6734 │       7.04 │             1670 │           4 │
-- │           2.5 │ 11508 │      12.02 │             1669 │           4 │
-- │          10.0 │  6701 │       7.00 │             1666 │           4 │
-- └───────────────┴───────┴────────────┴──────────────────┴─────────────┘
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
  COUNT(DISTINCT experiment_name) AS experiments
FROM read_csv_auto('metadata_rxrx3_core.csv'), total_compounds
WHERE perturbation_type = 'COMPOUND' AND concentration IS NOT NULL
GROUP BY concentration, total_count
ORDER BY concentration;

-- 4.2 Top treatments in COMPOUND experiments
-- Lists the most common treatments/compounds (excluding controls)
--
-- Example output:
-- ┌──────────────┬───────┐
-- │  treatment   │ count │
-- │   varchar    │ int64 │
-- ├──────────────┼───────┤
-- │ Rufinamide   │   352 │
-- │ Flavopiridol │   352 │
-- │ GDC-0994     │   352 │
-- │ MI-773       │   352 │
-- │ KPT-185      │   352 │
-- └──────────────┴───────┘
SELECT
  treatment,
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'COMPOUND' 
  AND treatment <> 'EMPTY_control'
  AND treatment <> 'CRISPR_control'
GROUP BY treatment
ORDER BY count DESC
LIMIT 10;

-- 4.3 SMILES analysis for compounds
-- Analyzes compounds with SMILES notation
--
-- Example output:
-- ┌────────────┬────────────────┬─────────────┬─────────────────┬─────────────────┐
-- │ has_smiles │ compound_count │ total_wells │ avg_occurrences │ max_occurrences │
-- │  boolean   │     int64      │   int128    │     double      │      int64      │
-- ├────────────┼────────────────┼─────────────┼─────────────────┼─────────────────┤
-- │ false      │              2 │       32296 │         16148.0 │           22062 │
-- │ true       │           1674 │       63405 │            37.9 │             352 │
-- └────────────┴────────────────┴─────────────┴─────────────────┴─────────────────┘
WITH smiles_data AS (
  SELECT
    treatment,
    COUNT(*) AS occurrences,
    SMILES IS NOT NULL AND SMILES <> '' AS has_smiles,
    COUNT(DISTINCT concentration) AS concentration_levels,
    COUNT(DISTINCT experiment_name) AS experiments
  FROM read_csv_auto('metadata_rxrx3_core.csv')
  WHERE perturbation_type = 'COMPOUND'
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

-- =============================================
-- 5. CONTROL ANALYSIS
-- =============================================

-- 5.1 Control distribution
-- Shows how controls are distributed across experiments
--
-- Example output:
-- ┌─────────────────┬───────────┬────────────────┬─────────────────┬─────────────┬─────────────────┐
-- │ experiment_name │gene_cntrls│ empty_controls │ crispr_controls │ total_wells │ control_percent │
-- │     varchar     │  int128   │     int128     │     int128      │    int64    │     double      │
-- ├─────────────────┼───────────┼────────────────┼─────────────────┼─────────────┼─────────────────┤
-- │ compound-003    │         0 │          8788 │            8812 │       39664 │           44.37 │
-- │ compound-001    │         0 │          4820 │            6200 │       28231 │           39.03 │
-- │ compound-002    │         0 │          1550 │            1650 │        6681 │           47.90 │
-- └─────────────────┴───────────┴────────────────┴─────────────────┴─────────────┴─────────────────┘
SELECT
  experiment_name,
  SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) AS gene_controls,
  SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) AS empty_controls,
  SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS crispr_controls,
  COUNT(*) AS total_wells,
  ROUND((SUM(CASE WHEN gene = 'EMPTY_control' THEN 1 ELSE 0 END) + 
         SUM(CASE WHEN treatment = 'EMPTY_control' THEN 1 ELSE 0 END) +
         SUM(CASE WHEN treatment = 'CRISPR_control' THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2) AS control_percent
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY experiment_name
ORDER BY total_wells DESC
LIMIT 10;

-- =============================================
-- 6. PLATE AND WELL ANALYSIS
-- =============================================

-- 6.1 Plate statistics
-- Analyzes plate distribution and composition
--
-- Example output:
-- ┌───────┬───────┬─────────────┬─────────────┬───────────────┬───────────────┐
-- │ plate │ wells │ experiments │ crispr_wells│ compound_wells│  control_pct  │
-- │ int64 │ int64 │    int64    │    int128   │     int128    │    double     │
-- ├───────┼───────┼─────────────┼─────────────┼───────────────┼───────────────┤
-- │    11 │  6136 │          95 │        3496 │          2640 │         45.15 │
-- │    35 │  6119 │          94 │        3496 │          2623 │         44.94 │
-- │    33 │  6099 │          94 │        3481 │          2618 │         45.02 │
-- └───────┴───────┴─────────────┴─────────────┴───────────────┴───────────────┘
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

-- 6.2 Well position (address) analysis
-- Shows patterns in well positions across the plates
--
-- Example output:
-- ┌─────────┬───────┬────────┬─────────────┬───────────────┬────────────┐
-- │ address │ wells │ plates │ experiments │ control_wells │ control_pct│
-- │ varchar │ int64 │ int64  │    int64    │     int64     │   double   │
-- ├─────────┼───────┼────────┼─────────────┼───────────────┼────────────┤
-- │ H05     │  1048 │     48 │         168 │           348 │      33.21 │
-- │ H07     │  1034 │     48 │         162 │           335 │      32.40 │
-- │ H04     │  1031 │     48 │         159 │           339 │      32.88 │
-- └─────────┴───────┴────────┴─────────────┴───────────────┴────────────┘
SELECT
  address,
  COUNT(*) AS wells,
  COUNT(DISTINCT plate) AS plates,
  COUNT(DISTINCT experiment_name) AS experiments,
  SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' OR treatment = 'CRISPR_control' THEN 1 ELSE 0 END) AS control_wells,
  ROUND(SUM(CASE WHEN gene = 'EMPTY_control' OR treatment = 'EMPTY_control' OR treatment = 'CRISPR_control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS control_pct
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY address
ORDER BY wells DESC
LIMIT 10;

-- =============================================
-- 7. ADVANCED RELATIONSHIP ANALYSIS
-- =============================================

-- 7.1 Gene-Treatment correlation
-- Finds genes and treatments that frequently appear together
--
-- Example output:
-- ┌───────┬────────────┬─────────────┬─────────────┬───────────────────┬──────────────────────┐
-- │ gene  │ treatment  │ occurrences │ experiments │ pct_of_gene       │ pct_of_treatment     │
-- │varchar│  varchar   │    int64    │    int64    │      double       │        double        │
-- ├───────┼────────────┼─────────────┼─────────────┼───────────────────┼──────────────────────┤
-- │ MTOR  │ Rapamycin  │         153 │         153 │             1.62  │                80.53 │
-- │ KIT   │ Imatinib   │         127 │         127 │             8.03  │                82.47 │
-- │ HDAC1 │ Vorinostat │         113 │         113 │            10.18  │                71.97 │
-- └───────┴────────────┴─────────────┴─────────────┴───────────────────┴──────────────────────┘
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
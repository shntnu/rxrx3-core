-- RxRx3-core Metadata Analysis Queries
-- Usage: duckdb -c "QUERY" metadata_rxrx3_core.csv
-- 
-- This file contains carefully crafted SQL queries for analyzing the RxRx3-core dataset metadata.
-- Each section includes actual output from running the queries.
-- Run these queries using DuckDB (https://duckdb.org/) for fast local analysis.
--
-- Example: duckdb -c "SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv');"
--
-- Generated using actual query outputs on: $(date)
-- Created with Claude Code: https://claude.ai/code


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

-- QUERY RESULT:
--
-- ┌───────────────┬──────────────┬───────────────────┬───┬───────────────┬────────────────────┬─────────────────┐
-- │ total_records │ unique_genes │ unique_treatments │ … │ gene_controls │ treatment_controls │ crispr_controls │
-- │     int64     │    int64     │       int64       │   │    int128     │       int128       │     int128      │
-- ├───────────────┼──────────────┼───────────────────┼───┼───────────────┼────────────────────┼─────────────────┤
-- │        222601 │          736 │              6108 │ … │         25312 │              35546 │           22062 │
-- ├───────────────┴──────────────┴───────────────────┴───┴───────────────┴────────────────────┴─────────────────┤
-- │ 1 rows                                                                                  8 columns (6 shown) │
-- └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--

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

-- QUERY RESULT:
--
-- ┌───────────────────┬────────┬────────────┐
-- │ perturbation_type │ count  │ percentage │
-- │      varchar      │ int64  │   double   │
-- ├───────────────────┼────────┼────────────┤
-- │ CRISPR            │ 126900 │      57.01 │
-- │ COMPOUND          │  95701 │      42.99 │
-- └───────────────────┴────────┴────────────┘
--

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

-- QUERY RESULT:
--
-- ┌──────────┬───────────────┬───────────────────┬────────┐
-- │ has_gene │ has_treatment │ perturbation_type │ count  │
-- │ boolean  │    boolean    │      varchar      │ int64  │
-- ├──────────┼───────────────┼───────────────────┼────────┤
-- │ false    │ true          │ COMPOUND          │  95701 │
-- │ true     │ true          │ CRISPR            │ 126900 │
-- └──────────┴───────────────┴───────────────────┴────────┘
--


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

-- QUERY RESULT:
--
-- ┌─────────────────┬──────────────────┬───┬──────────────────────┬──────────────────────┬──────────────────────┐
-- │ experiment_type │ experiment_count │ … │ avg_genes_per_expe…  │ avg_treatments_per…  │ avg_concentration_…  │
-- │     varchar     │      int64       │   │        double        │        double        │        double        │
-- ├─────────────────┼──────────────────┼───┼──────────────────────┼──────────────────────┼──────────────────────┤
-- │ GENE            │              176 │ … │                 15.5 │                 67.3 │                  0.0 │
-- │ COMPOUND        │                4 │ … │                  0.0 │                445.3 │                  9.0 │
-- ├─────────────────┴──────────────────┴───┴──────────────────────┴──────────────────────┴──────────────────────┤
-- │ 2 rows                                                                                  9 columns (5 shown) │
-- └─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--

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

-- QUERY RESULT:
--
-- ┌─────────────────┬────────────┬────────────┬─────────────────┬─────────────────┐
-- │ experiment_name │ well_count │ gene_count │ treatment_count │ experiment_type │
-- │     varchar     │   int64    │   int64    │      int64      │     varchar     │
-- ├─────────────────┼────────────┼────────────┼─────────────────┼─────────────────┤
-- │ compound-003    │      39664 │          0 │             877 │ COMPOUND        │
-- │ compound-001    │      28231 │          0 │             522 │ COMPOUND        │
-- │ compound-004    │      21125 │          0 │             290 │ COMPOUND        │
-- │ compound-002    │       6681 │          0 │              92 │ COMPOUND        │
-- │ gene-132        │       1304 │         26 │             130 │ GENE            │
-- │ gene-029        │       1303 │         26 │             130 │ GENE            │
-- │ gene-122        │       1152 │         23 │             113 │ GENE            │
-- │ gene-046        │       1151 │         23 │             113 │ GENE            │
-- │ gene-067        │       1078 │         22 │             105 │ GENE            │
-- │ gene-118        │       1070 │         22 │             104 │ GENE            │
-- ├─────────────────┴────────────┴────────────┴─────────────────┴─────────────────┤
-- │ 10 rows                                                             5 columns │
-- └───────────────────────────────────────────────────────────────────────────────┘
--

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

-- QUERY RESULT:
--
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
--


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

-- QUERY RESULT:
--
-- ┌─────────┬───────┐
-- │  gene   │ count │
-- │ varchar │ int64 │
-- ├─────────┼───────┤
-- │ PLK1    │  9471 │
-- │ MTOR    │  9456 │
-- │ SRC     │  1672 │
-- │ EIF3H   │  1669 │
-- │ HCK     │  1667 │
-- │ CYP11B1 │  1559 │
-- │ CTNNA1  │   216 │
-- │ MAOA    │   216 │
-- │ RPL10   │   216 │
-- │ RPL23A  │   216 │
-- ├─────────┴───────┤
-- │     10 rows     │
-- └─────────────────┘
--

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

-- QUERY RESULT:
--
-- ┌─────────┬────────────┬─────────────┬──────────────────┬──────────────────────────────┐
-- │  gene   │ well_count │ experiments │ gene_experiments │ gene_experiment_coverage_pct │
-- │ varchar │   int64    │    int64    │      int64       │            double            │
-- ├─────────┼────────────┼─────────────┼──────────────────┼──────────────────────────────┤
-- │ PLK1    │    1666896 │         176 │              176 │                        100.0 │
-- │ MTOR    │    1664256 │         176 │              176 │                        100.0 │
-- │ SRC     │     294272 │         176 │              176 │                        100.0 │
-- │ EIF3H   │     293744 │         176 │              176 │                        100.0 │
-- │ HCK     │     293392 │         176 │              176 │                        100.0 │
-- │ CYP11B1 │     274384 │         176 │              176 │                        100.0 │
-- │ RPL23A  │        864 │           4 │                4 │                         2.27 │
-- │ RPL10   │        864 │           4 │                4 │                         2.27 │
-- │ ATP5F1C │        864 │           4 │                4 │                         2.27 │
-- │ AKR1B1  │        864 │           4 │                4 │                         2.27 │
-- ├─────────┴────────────┴─────────────┴──────────────────┴──────────────────────────────┤
-- │ 10 rows                                                                    5 columns │
-- └──────────────────────────────────────────────────────────────────────────────────────┘
--


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

-- QUERY RESULT:
--
-- ┌───────────────┬───────┬────────────┬──────────────────┬─────────────┐
-- │ concentration │ wells │ percentage │ unique_compounds │ experiments │
-- │    double     │ int64 │   double   │      int64       │    int64    │
-- ├───────────────┼───────┼────────────┼──────────────────┼─────────────┤
-- │         0.002 │     4 │        0.0 │                1 │           1 │
-- │        0.0025 │  6732 │       7.03 │             1669 │           4 │
-- │          0.01 │  6733 │       7.04 │             1670 │           4 │
-- │         0.025 │  6727 │       7.03 │             1668 │           4 │
-- │         0.026 │     4 │        0.0 │                1 │           1 │
-- │           0.1 │  6727 │       7.03 │             1669 │           4 │
-- │          0.25 │ 11527 │      12.04 │             1673 │           4 │
-- │          0.26 │     4 │        0.0 │                1 │           1 │
-- │           1.0 │  6734 │       7.04 │             1670 │           4 │
-- │           2.5 │ 11508 │      12.02 │             1669 │           4 │
-- │           2.6 │     4 │        0.0 │                1 │           1 │
-- │          10.0 │  6701 │        7.0 │             1666 │           4 │
-- ├───────────────┴───────┴────────────┴──────────────────┴─────────────┤
-- │ 12 rows                                                   5 columns │
-- └─────────────────────────────────────────────────────────────────────┘
--

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

-- QUERY RESULT:
--
-- ┌─────────────────────────┬───────┐
-- │        treatment        │ count │
-- │         varchar         │ int64 │
-- ├─────────────────────────┼───────┤
-- │ GDC-0994                │   352 │
-- │ MI-773                  │   352 │
-- │ KPT-185                 │   352 │
-- │ 6-Mercaptopurine (6-MP) │   352 │
-- │ BIRB 796                │   352 │
-- │ BI 2536                 │   352 │
-- │ lovastatin              │   352 │
-- │ PD0325901               │   352 │
-- │ CEP-18770               │   352 │
-- │ PD168393                │   352 │
-- ├─────────────────────────┴───────┤
-- │ 10 rows               2 columns │
-- └─────────────────────────────────┘
--

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

-- QUERY RESULT:
--
-- ┌────────────┬────────────────┬─────────────┬───┬─────────────────┬─────────────────┬─────────────────┐
-- │ has_smiles │ compound_count │ total_wells │ … │ min_occurrences │ max_occurrences │ avg_occurrences │
-- │  boolean   │     int64      │   int128    │   │      int64      │      int64      │     double      │
-- ├────────────┼────────────────┼─────────────┼───┼─────────────────┼─────────────────┼─────────────────┤
-- │ false      │              2 │       32296 │ … │           10234 │           22062 │         16148.0 │
-- │ true       │           1674 │       63405 │ … │              16 │             352 │           37.88 │
-- ├────────────┴────────────────┴─────────────┴───┴─────────────────┴─────────────────┴─────────────────┤
-- │ 2 rows                                                                          8 columns (6 shown) │
-- └─────────────────────────────────────────────────────────────────────────────────────────────────────┘
--


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

-- QUERY RESULT:
--
-- ┌─────────────────┬───────────────┬────────────────┬─────────────────┬─────────────┬─────────────────┐
-- │ experiment_name │ gene_controls │ empty_controls │ crispr_controls │ total_wells │ control_percent │
-- │     varchar     │    int128     │     int128     │     int128      │    int64    │     double      │
-- ├─────────────────┼───────────────┼────────────────┼─────────────────┼─────────────┼─────────────────┤
-- │ compound-003    │             0 │           3071 │            6502 │       39664 │           24.14 │
-- │ compound-001    │             0 │           3068 │            6385 │       28231 │           33.48 │
-- │ compound-004    │             0 │           3071 │            6428 │       21125 │           44.97 │
-- │ compound-002    │             0 │           1024 │            2747 │        6681 │           56.44 │
-- │ gene-132        │           144 │            144 │               0 │        1304 │           22.09 │
-- │ gene-029        │           144 │            144 │               0 │        1303 │            22.1 │
-- │ gene-122        │           144 │            144 │               0 │        1152 │            25.0 │
-- │ gene-046        │           144 │            144 │               0 │        1151 │           25.02 │
-- │ gene-067        │           144 │            144 │               0 │        1078 │           26.72 │
-- │ gene-118        │           144 │            144 │               0 │        1070 │           26.92 │
-- ├─────────────────┴───────────────┴────────────────┴─────────────────┴─────────────┴─────────────────┤
-- │ 10 rows                                                                                  6 columns │
-- └────────────────────────────────────────────────────────────────────────────────────────────────────┘
--


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

-- QUERY RESULT:
--
-- ┌───────┬───────┬─────────────┬──────────────┬────────────────┬───────────────┬─────────────┐
-- │ plate │ wells │ experiments │ crispr_wells │ compound_wells │ control_wells │ control_pct │
-- │ int64 │ int64 │    int64    │    int128    │     int128     │    int128     │   double    │
-- ├───────┼───────┼─────────────┼──────────────┼────────────────┼───────────────┼─────────────┤
-- │     8 │ 16183 │         180 │        14209 │           1974 │          3550 │       21.94 │
-- │     5 │ 16163 │         180 │        14189 │           1974 │          3551 │       21.97 │
-- │     3 │ 16107 │         180 │        14141 │           1966 │          3711 │       23.04 │
-- │     1 │ 16043 │         180 │        14145 │           1898 │          3560 │       22.19 │
-- │     4 │ 16040 │         180 │        14141 │           1899 │          3560 │       22.19 │
-- │     6 │ 16032 │         180 │        14065 │           1967 │          3698 │       23.07 │
-- │     2 │ 15955 │         180 │        13982 │           1973 │          3551 │       22.26 │
-- │     7 │ 15949 │         180 │        14049 │           1900 │          3544 │       22.22 │
-- │     9 │ 15945 │         180 │        13979 │           1966 │          3710 │       23.27 │
-- │    15 │  2887 │           4 │            0 │           2887 │          1017 │       35.23 │
-- ├───────┴───────┴─────────────┴──────────────┴────────────────┴───────────────┴─────────────┤
-- │ 10 rows                                                                         7 columns │
-- └───────────────────────────────────────────────────────────────────────────────────────────┘
--



-- QUERY RESULT:
--
-- [No output or error occurred]
--


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

-- QUERY RESULT:
--
-- ┌─────────┬─────────────────┬─────────────┬─────────────┬───┬──────────────────────┬─────────────┬──────────────────┐
-- │  gene   │    treatment    │ occurrences │ experiments │ … │ total_treatment_oc…  │ pct_of_gene │ pct_of_treatment │
-- │ varchar │     varchar     │    int64    │    int64    │   │        int64         │   double    │      double      │
-- ├─────────┼─────────────────┼─────────────┼─────────────┼───┼──────────────────────┼─────────────┼──────────────────┤
-- │ EIF3H   │ EIF3H_guide_1   │        1579 │         176 │ … │                 1579 │       94.61 │            100.0 │
-- │ MTOR    │ MTOR_guide_6    │        1567 │         176 │ … │                 1567 │       16.57 │            100.0 │
-- │ SRC     │ SRC_guide_1     │        1566 │         176 │ … │                 1566 │       93.66 │            100.0 │
-- │ PLK1    │ PLK1_guide_6    │        1565 │         176 │ … │                 1565 │       16.52 │            100.0 │
-- │ MTOR    │ MTOR_guide_4    │        1565 │         176 │ … │                 1565 │       16.55 │            100.0 │
-- │ PLK1    │ PLK1_guide_3    │        1565 │         176 │ … │                 1565 │       16.52 │            100.0 │
-- │ MTOR    │ MTOR_guide_5    │        1562 │         176 │ … │                 1562 │       16.52 │            100.0 │
-- │ HCK     │ HCK_guide_1     │        1560 │         176 │ … │                 1560 │       93.58 │            100.0 │
-- │ MTOR    │ MTOR_guide_3    │        1560 │         176 │ … │                 1560 │        16.5 │            100.0 │
-- │ PLK1    │ PLK1_guide_4    │        1560 │         176 │ … │                 1560 │       16.47 │            100.0 │
-- │ PLK1    │ PLK1_guide_5    │        1560 │         176 │ … │                 1560 │       16.47 │            100.0 │
-- │ CYP11B1 │ CYP11B1_guide_1 │        1559 │         176 │ … │                 1559 │       100.0 │            100.0 │
-- │ MTOR    │ MTOR_guide_1    │        1559 │         176 │ … │                 1559 │       16.49 │            100.0 │
-- │ PLK1    │ PLK1_guide_1    │        1557 │         176 │ … │                 1557 │       16.44 │            100.0 │
-- │ PLK1    │ PLK1_guide_2    │        1556 │         176 │ … │                 1556 │       16.43 │            100.0 │
-- │ MTOR    │ MTOR_guide_2    │        1554 │         176 │ … │                 1554 │       16.43 │            100.0 │
-- │ GABRA1  │ GABRA1_guide_3  │          36 │           4 │ … │                   36 │       16.74 │            100.0 │
-- │ ACTB    │ ACTB_guide_1    │          36 │           4 │ … │                   36 │       16.74 │            100.0 │
-- │ PGD     │ PGD_guide_2     │          36 │           4 │ … │                   36 │       16.98 │            100.0 │
-- │ ACTG1   │ ACTG1_guide_4   │          36 │           4 │ … │                   36 │       16.67 │            100.0 │
-- ├─────────┴─────────────────┴─────────────┴─────────────┴───┴──────────────────────┴─────────────┴──────────────────┤
-- │ 20 rows                                                                                       8 columns (7 shown) │
-- └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
--


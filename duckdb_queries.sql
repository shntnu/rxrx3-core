-- DuckDB queries for inspecting RxRx3-core metadata
-- Usage: duckdb -c "QUERY" or run in DuckDB shell

-- Basic dataset stats
SELECT 
  COUNT(*) AS total_records,
  COUNT(DISTINCT gene) AS unique_genes,
  COUNT(DISTINCT treatment) AS unique_treatments,
  COUNT(DISTINCT experiment_name) AS unique_experiments
FROM read_csv_auto('metadata_rxrx3_core.csv');

-- Distribution by perturbation type
SELECT 
  perturbation_type, 
  COUNT(*) AS count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv')), 2) AS percentage
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY perturbation_type
ORDER BY count DESC;

-- Distribution by cell type
SELECT 
  cell_type, 
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY cell_type
ORDER BY count DESC;

-- Distribution of concentration values for compounds
SELECT 
  concentration, 
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'COMPOUND' AND concentration IS NOT NULL
GROUP BY concentration
ORDER BY concentration;

-- Top 10 most common genes in CRISPR perturbation
SELECT 
  gene, 
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'CRISPR' AND gene != ''
GROUP BY gene
ORDER BY count DESC
LIMIT 10;

-- Top 10 most common treatments in COMPOUND perturbation
SELECT 
  treatment, 
  COUNT(*) AS count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE perturbation_type = 'COMPOUND' AND treatment != 'EMPTY_control'
GROUP BY treatment
ORDER BY count DESC
LIMIT 10;

-- Find all experiments for a specific gene
SELECT 
  experiment_name, 
  COUNT(*) AS record_count
FROM read_csv_auto('metadata_rxrx3_core.csv')
WHERE gene = 'REPLACE_WITH_GENE_NAME'
GROUP BY experiment_name;

-- Explore experiment distribution
SELECT 
  experiment_name, 
  COUNT(*) AS record_count,
  COUNT(DISTINCT gene) AS unique_genes,
  COUNT(DISTINCT treatment) AS unique_treatments
FROM read_csv_auto('metadata_rxrx3_core.csv')
GROUP BY experiment_name
ORDER BY record_count DESC;

-- Join with embeddings (assuming parquet file is available)
-- This query creates a view joining metadata with embeddings
-- Note: Adjust the parquet path if needed
CREATE OR REPLACE VIEW rxrx3_with_embeddings AS
SELECT 
  m.*, 
  e.* EXCLUDE (well_id)
FROM 
  read_csv_auto('metadata_rxrx3_core.csv') AS m
JOIN 
  read_parquet('OpenPhenom_rxrx3_core_embeddings.parquet') AS e
ON 
  m.well_id = e.well_id;

-- Example query using the view to analyze embeddings by perturbation
SELECT 
  perturbation_type, 
  AVG(embedding_0) AS avg_emb_0,
  AVG(embedding_1) AS avg_emb_1,
  -- Add more embedding dimensions as needed
  COUNT(*) AS count
FROM rxrx3_with_embeddings
GROUP BY perturbation_type;
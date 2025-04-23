# RxRx3-core Dataset and Analysis Tools

---
dataset_info:
  features:
  - name: __key__
    dtype: string
  - name: jp2
    dtype: image
  splits:
  - name: train
    num_bytes: 17489993120.108
    num_examples: 1335606
  download_size: 17390577507
  dataset_size: 17489993120.108
configs:
- config_name: default
  data_files:
  - split: train
    path: data/train-*
---

## Dataset Overview

To accompany OpenPhenom, Recursion is releasing the [**RxRx3-core**](https://arxiv.org/abs/2503.20158) dataset, a challenge dataset in phenomics optimized for the research community. 
RxRx3-core includes labeled images of 735 genetic knockouts and 1,674 small-molecule perturbations drawn from the [RxRx3 dataset](https://www.rxrx.ai/rxrx3), 
image embeddings computed with [OpenPhenom](https://huggingface.co/recursionpharma/OpenPhenom), and associations between the included small molecules and genes. 
The dataset contains 6-channel Cell Painting images and associated embeddings from 222,601 wells but is less than 18Gb, making it incredibly accessible to the research community.

Mapping the mechanisms by which drugs exert their actions is an important challenge in advancing the use of high-dimensional biological data like phenomics. 
We are excited to release the first dataset of this scale probing concentration-response along with a benchmark and model to enable the research community to 
rapidly advance this space.

Paper published at LMRL Workshop at ICLR 2025 [RxRx3-core: Benchmarking drug-target interactions in High-Content Microscopy](https://arxiv.org/abs/2503.20158).  
Benchmarking code for this dataset is provided in the [EFAAR benchmarking repo](https://github.com/recursionpharma/EFAAR_benchmarking/tree/trunk/RxRx3-core_benchmarks) and [Polaris](https://polarishub.io/benchmarks/recursion/rxrx-compound-gene-activity-benchmark).

## Loading the Dataset

### Loading the RxRx3-core image dataset
```python
from datasets import load_dataset
rxrx3_core = load_dataset("recursionpharma/rxrx3-core")
```

### Loading OpenPhenom embeddings and metadata for RxRx3-core
```python
from huggingface_hub import hf_hub_download
import pandas as pd

file_path_metadata = hf_hub_download("recursionpharma/rxrx3-core", filename="metadata_rxrx3_core.csv", repo_type="dataset")
file_path_embs = hf_hub_download("recursionpharma/rxrx3-core", filename="OpenPhenom_rxrx3_core_embeddings.parquet", repo_type="dataset")

open_phenom_embeddings = pd.read_parquet(file_path_embs)
rxrx3_core_metadata = pd.read_csv(file_path_metadata)
```

## Analysis Tools Included in This Repository

This repository includes several tools to help analyze the RxRx3-core metadata:

1. **SQL Query Files**: Collection of DuckDB queries for exploring the dataset:
   - `duckdb_queries.sql`: Basic queries for initial exploration
   - `improved_duckdb_queries.sql`: More detailed analysis queries
   - `final_duckdb_queries.sql`: Advanced queries for comprehensive insights

2. **Dataset Insights**: The `rxrx3_core_insights.md` file provides a summary of key findings from analyzing the dataset metadata, including:
   - Distribution of experiment types
   - Concentration patterns in compound experiments
   - Gene and treatment statistics
   - Control sample analysis
   
3. **Claude.md**: Guidelines for AI assistants (like Claude) working with this codebase

## Using the SQL Queries

The SQL queries are designed to work with DuckDB, a lightweight analytical database that works well with CSV files.

Example usage:
```bash
# Install DuckDB if needed
# Basic stats query
duckdb -c "SELECT COUNT(*) AS total_records, COUNT(DISTINCT gene) AS unique_genes FROM read_csv_auto('metadata_rxrx3_core.csv');"

# Run a query file
duckdb -c "$(cat final_duckdb_queries.sql | grep -A20 '-- 1. Summary')"
```

## Key Insights

The RxRx3-core dataset contains:
- 222,601 wells with 736 unique genes and 6,108 unique treatments
- 57% CRISPR perturbations and 43% COMPOUND perturbations
- All samples use HUVEC cell type (human umbilical vein endothelial cells)
- 4 large compound experiments and 176 gene experiments
- Multiple concentration levels for compounds (0.0025μM through 10.0μM)

For more detailed insights, see the `rxrx3_core_insights.md` file.
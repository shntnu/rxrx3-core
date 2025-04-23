# RxRx3-core Analysis

This repository contains analysis tools and insights for the RxRx3-core dataset, with data sourced from [Hugging Face](https://huggingface.co/datasets/recursionpharma/rxrx3-core).

## About the Dataset

The RxRx3-core dataset is a challenge dataset in phenomics from Recursion Pharmaceuticals. It includes:

- Labeled images of 735 genetic knockouts and 1,674 small-molecule perturbations drawn from the RxRx3 dataset
- Image embeddings computed with OpenPhenom
- Associations between small molecules and genes
- 6-channel Cell Painting images and associated embeddings from 222,601 wells

For more information about the dataset, visit:
- [Hugging Face dataset page](https://huggingface.co/datasets/recursionpharma/rxrx3-core)
- [RxRx3 dataset website](https://www.rxrx.ai/rxrx3)
- Research paper: [RxRx3-core: Benchmarking drug-target interactions in High-Content Microscopy](https://arxiv.org/abs/2503.20158)

## Repository Purpose

This repository was created to analyze the RxRx3-core metadata using Claude Code (Anthropic's AI coding assistant). It includes:

1. **SQL Analysis File**: A comprehensive DuckDB SQL analysis file with embedded example outputs:
   - `rxrx3_metadata_analysis.sql`: Contains carefully organized SQL queries for analyzing all aspects of the dataset
   - Each query includes example output as comments so you know what to expect

2. **Analysis Results**: The `rxrx3_core_insights.md` file provides a summary of key findings from the dataset metadata analysis.

3. **Claude.md**: Guidelines for AI assistants working with this repository.

## Key Findings

Through our analysis, we discovered:

- The dataset contains 222,601 wells with 736 unique genes and 6,108 unique treatments
- It's split between CRISPR (57%) and COMPOUND (43%) perturbations
- All samples use HUVEC cell type (human umbilical vein endothelial cells)
- The dataset includes 4 large compound experiments and 176 gene experiments
- Compounds are tested at multiple concentration levels (0.0025μM through 10.0μM)

For detailed insights, see the `rxrx3_core_insights.md` file.

## Using This Repository

To explore the metadata yourself:

1. Download the metadata file from Hugging Face:
   ```python
   from huggingface_hub import hf_hub_download
   file_path_metadata = hf_hub_download("recursionpharma/rxrx3-core", filename="metadata_rxrx3_core.csv", repo_type="dataset")
   ```

2. Install DuckDB and run the analysis queries:
   ```bash
   # Run a specific query
   duckdb -c "SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv');"
   
   # Run a section from the analysis file (example: perturbation type distribution)
   duckdb -c "$(grep -A10 '-- 1.2 Perturbation type distribution' rxrx3_metadata_analysis.sql | grep -v '^--' | head -n 8)"
   ```

## Acknowledgments

- Original dataset provided by Recursion Pharmaceuticals
- Analysis performed using Claude Code (Anthropic's AI coding assistant)
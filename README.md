# RxRx3-core Analysis

This repository contains analysis tools and insights for the RxRx3-core dataset metadata.

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

This repository was created to analyze the RxRx3-core dataset metadata using Claude Code (Anthropic's AI coding assistant). It includes:

1. **Metadata File**: The `metadata_rxrx3_core.csv` file containing all dataset metadata

2. **SQL Analysis File**: A comprehensive DuckDB SQL analysis file with embedded query outputs:
   - `rxrx3_metadata_analysis.sql`: Contains carefully organized SQL queries for analyzing all aspects of the dataset
   - Each query includes actual output as comments showing exactly what to expect
   - Generated using `generate_annotated_sql.sh` which runs queries and captures outputs

3. **Claude.md**: Guidelines for AI assistants working with this repository.

## Dataset Insights

Our analysis of the metadata revealed the following insights:

### Overview

The RxRx3-core dataset contains **222,601 wells** of 6-channel Cell Painting images, with the following key characteristics:
- **736 unique genes** and **6,108 unique treatments**
- **180 distinct experiments** across **48 unique plates**
- **57.01% CRISPR perturbations** (126,900 wells) and **42.99% COMPOUND perturbations** (95,701 wells)
- All samples use **HUVEC cell type** (human umbilical vein endothelial cells)

### Experiment Structure

The dataset has two main experiment types:
- **GENE experiments (176)**: Average of 15.5 genes and 67.3 treatments per experiment
- **COMPOUND experiments (4)**: Average of 445.3 treatments per experiment with 9 concentration levels

Experiment size distribution:
- Most experiments (153) are medium-sized (500-999 wells)
- Only 3 experiments are very large (10,000+ wells), but they account for 89,020 wells (40% of the dataset)
- The largest experiment (compound-003) contains 39,664 wells

### Control Samples

Control samples make up a significant portion of the dataset:
- **25,312 EMPTY_control gene wells** (11.4% of all wells)
- **35,546 EMPTY_control treatment wells** (16.0% of all wells)
- **22,062 CRISPR_control treatment wells** (9.9% of all wells)

### Compound Data

Compound perturbations have several concentration levels:
- Most common concentrations: **0.25 μM** (12.04% of compound wells) and **2.5 μM** (12.02%)
- **1,674 unique compounds with SMILES notation** in 63,405 wells
- Each compound appears in an average of 37.88 wells
- Most compounds are tested at 8 different concentration levels across 4 experiments

### CRISPR Perturbations

CRISPR perturbations target specific genes:
- **Top genes**: PLK1 (9,471 wells) and MTOR (9,456 wells)
- Beyond controls, these two genes account for 15% of all CRISPR perturbations
- The most studied genes (PLK1, MTOR, SRC, EIF3H, HCK) appear in all 176 gene experiments
- There's a distinct tier of genes that appear in only a small number of experiments (2.27%)

### Dataset Structure

The dataset is organized into experiments that follow naming patterns:
- `gene-XXX`: CRISPR gene perturbation experiments (176 experiments)
- `compound-XXX`: Small molecule compound experiments (4 experiments)

The largest experiments focus on compounds:
1. compound-003: 39,664 wells, 877 unique treatments
2. compound-001: 28,231 wells, 522 unique treatments
3. compound-004: 21,125 wells, 290 unique treatments
4. compound-002: 6,681 wells, 92 unique treatments

## Using This Repository

To explore the metadata yourself:

1. Clone this repository to get the `metadata_rxrx3_core.csv` file

2. Install DuckDB and run the analysis queries:
   ```bash
   # Run a specific query
   duckdb -c "SELECT COUNT(*) FROM read_csv_auto('metadata_rxrx3_core.csv');"
   
   # Run a section from the analysis file (example: perturbation type distribution)
   duckdb -c "$(grep -A10 '-- 1.2 Perturbation type distribution' rxrx3_metadata_analysis.sql | grep -v '^--' | head -n 8)"
   ```

3. Generate your own annotated SQL file:
   ```bash
   # Make the script executable if needed
   chmod +x generate_annotated_sql.sh
   
   # Run the script to generate an annotated SQL file with your current data
   ./generate_annotated_sql.sh
   ```

## Usage Notes

When working with this dataset:
1. Be aware of the high proportion of control wells (over 37%)
2. Consider the concentration variations in compound experiments
3. Leverage the SMILES notation for chemical structure analysis
4. Note that all experiments use the same cell type (HUVEC)
5. Compound experiments are fewer but larger than gene experiments

## Acknowledgments

- Original dataset provided by Recursion Pharmaceuticals
- Metadata sourced from [Hugging Face](https://huggingface.co/datasets/recursionpharma/rxrx3-core)
- Analysis performed using Claude Code (Anthropic's AI coding assistant)
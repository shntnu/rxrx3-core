# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Dataset Information
- RxRx3-core: Phenomics dataset with labeled images of genetic knockouts and small-molecule perturbations
- Contains 222,601 wells of 6-channel Cell Painting images (less than 18GB)
- Includes images, OpenPhenom embeddings, and small molecule-gene associations

## Code Guidelines
- Python-based data analysis
- Use pandas for data manipulation and analysis
- Follow PEP 8 for Python code style
- Use type hints in function definitions
- Organize imports: standard library, third-party, local modules
- Handle errors with try/except blocks and informative error messages

## Data Loading Commands
```python
from datasets import load_dataset
rxrx3_core = load_dataset("recursionpharma/rxrx3-core")

from huggingface_hub import hf_hub_download
import pandas as pd
file_path_metadata = hf_hub_download("recursionpharma/rxrx3-core", filename="metadata_rxrx3_core.csv", repo_type="dataset")
file_path_embs = hf_hub_download("recursionpharma/rxrx3-core", filename="OpenPhenom_rxrx3_core_embeddings.parquet", repo_type="dataset")
```
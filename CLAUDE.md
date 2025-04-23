# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose
- Analysis repository for the RxRx3-core dataset metadata
- Contains SQL analysis scripts with embedded query results
- Uses DuckDB for local data analysis

## Dataset Details
- RxRx3-core: 222,601 wells of cell images (CRISPR and compound perturbations)
- 736 unique genes and 6,108 unique treatments
- All analyses based on metadata_rxrx3_core.csv file included in this repository

## Working with This Repository
- Use DuckDB for all SQL queries: `duckdb -c "QUERY" metadata_rxrx3_core.csv`
- Run generate_annotated_sql.sh to refresh query outputs with current data
- Keep README.md and SQL file documentation in sync

## Code Standards
- SQL: Use clear section headings and include output examples as comments
- Python: Follow PEP 8, use type hints, organize imports logically
- Shell scripts: Document parameters and include error handling

## Note
The metadata file (metadata_rxrx3_core.csv) is already included in this repository. No need to download it separately.
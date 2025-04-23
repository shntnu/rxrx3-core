#!/bin/bash

# Generate an annotated SQL file with actual query outputs
# This script extracts SQL queries from a template, runs them,
# and embeds the outputs as comments in the final SQL file

# Configuration
INPUT_FILE="rxrx3_metadata_analysis.sql"
OUTPUT_FILE="rxrx3_metadata_analysis_annotated.sql"
METADATA_FILE="metadata_rxrx3_core.csv"
TEMP_DIR="./tmp_query_outputs"

# Create temporary directory for query outputs
mkdir -p "$TEMP_DIR"

# Create output file with header
cat > "$OUTPUT_FILE" << 'EOF'
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

EOF

# Function to extract and run queries, capturing outputs
extract_and_run_query() {
    section_id="$1"
    section_name="$2"
    section_marker="-- $section_id $section_name"
    
    echo "Processing: $section_id $section_name"
    
    # Extract section header and description
    awk -v marker="$section_marker" '
        $0 ~ marker {flag=1; print; next}
        flag && /^--/ {print; next}
        flag && /^$/ {next}
        flag && !/^--/ {exit}
        0
    ' "$INPUT_FILE" >> "$OUTPUT_FILE"
    
    # Extract the SQL query
    query=$(awk -v marker="$section_marker" '
        $0 ~ marker {flag=1; next}
        flag && /^--/ {next}
        flag && /^$/ {next}
        flag && /;$/ {print; flag=0; exit}
        flag {print}
    ' "$INPUT_FILE")
    
    # Add query to output file
    echo "$query" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Run query and save output
    echo "Running query..."
    output_file="$TEMP_DIR/${section_id}.txt"
    duckdb -c "$query" > "$output_file"
    
    # Format the output as SQL comments
    echo "-- QUERY RESULT:" >> "$OUTPUT_FILE"
    echo "--" >> "$OUTPUT_FILE"
    
    # Check if output exists and has content
    if [ -s "$output_file" ]; then
        while IFS= read -r line; do
            echo "-- $line" >> "$OUTPUT_FILE"
        done < "$output_file"
    else
        echo "-- [No output or error occurred]" >> "$OUTPUT_FILE"
    fi
    
    echo "--" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Main sections to process - extracted from the original file
# Format: section_id "section_name"
sections=(
    "1.1" "Basic dataset statistics"
    "1.2" "Perturbation type distribution"
    "1.3" "Gene and treatment distribution"
    "2.1" "Experiment type analysis"
    "2.2" "Top experiments by size"
    "2.3" "Experiment size distribution by category"
    "3.1" "Top CRISPR genes"
    "3.2" "Gene distribution across experiments"
    "4.1" "Concentration distribution"
    "4.2" "Top treatments in COMPOUND experiments"
    "4.3" "SMILES analysis for compounds"
    "5.1" "Control distribution"
    "6.1" "Plate statistics"
    "6.2" "Well position (address) analysis"
    "7.1" "Gene-Treatment correlation"
)

# Process each section
for ((i=0; i<${#sections[@]}; i+=2)); do
    section_id="${sections[i]}"
    section_name="${sections[i+1]}"
    
    # Add section header
    if [[ "$section_id" == "1.1" ]]; then
        echo -e "\n-- =============================================\n-- 1. DATASET OVERVIEW\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "2.1" ]]; then
        echo -e "\n-- =============================================\n-- 2. EXPERIMENT ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "3.1" ]]; then
        echo -e "\n-- =============================================\n-- 3. CRISPR PERTURBATION ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "4.1" ]]; then
        echo -e "\n-- =============================================\n-- 4. COMPOUND PERTURBATION ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "5.1" ]]; then
        echo -e "\n-- =============================================\n-- 5. CONTROL ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "6.1" ]]; then
        echo -e "\n-- =============================================\n-- 6. PLATE AND WELL ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    elif [[ "$section_id" == "7.1" ]]; then
        echo -e "\n-- =============================================\n-- 7. ADVANCED RELATIONSHIP ANALYSIS\n-- =============================================\n" >> "$OUTPUT_FILE"
    fi
    
    extract_and_run_query "$section_id" "$section_name"
done

# Clean up
rm -rf "$TEMP_DIR"

echo "Annotated SQL file created: $OUTPUT_FILE"
#!/bin/bash

# Name: aggregate_text_files.sh
# Description: Aggregates non-hidden text files in a given directory into a single timestamped file.

if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

INPUT_PATH="$1"
TRANSIENT_DIR="${INPUT_PATH}/_transient-files"
TIMESTAMP=$(date +%Y-%m-%d)
DIRECTORY_NAME=$(basename "$INPUT_PATH")
OUTPUT_FILE="${TRANSIENT_DIR}/${TIMESTAMP}-${DIRECTORY_NAME}.txt"

# Create the transient directory if it does not exist
if [ ! -d "$TRANSIENT_DIR" ]; then
    mkdir -p "$TRANSIENT_DIR"
    echo "Created directory: $TRANSIENT_DIR"
fi

# Initialize the output file
> "$OUTPUT_FILE"
echo "Created output file: $OUTPUT_FILE"

# Iterate over the specified file types
FILE_EXTENSIONS=("*.txt" "*.md" "*.py" "*.yaml" "*.template" "*.toml" "Makefile")

for EXT in "${FILE_EXTENSIONS[@]}"; do
    find "$INPUT_PATH" -maxdepth 1 -type f -name "$EXT" ! -name ".*" | while read -r FILE; do
        FILENAME=$(basename "$FILE")
        FILEPATH=$(realpath "$FILE")

        echo "Processing: $FILEPATH"

        echo "here is $FILEPATH:" >> "$OUTPUT_FILE"
        echo "<$FILENAME>" >> "$OUTPUT_FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo "</$FILENAME>" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done

done

# Final status update
echo "All files aggregated into: $OUTPUT_FILE"

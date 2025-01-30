#!/bin/bash

# Name: aggregate_text_files.sh
# Description: Aggregates non-hidden text files in a given directory and its subdirectories into a single timestamped file, respecting .gitignore.

if [ -z "$1" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

INPUT_PATH="$1"
TRANSIENT_DIR="${INPUT_PATH}/_transient-files"
TIMESTAMP=$(date +%Y-%m-%d)
DIRECTORY_NAME=$(basename "$INPUT_PATH")
OUTPUT_FILE="${TRANSIENT_DIR}/${TIMESTAMP}-${DIRECTORY_NAME}.txt"

# Check if git and .gitignore exist
USE_GITIGNORE=false
if [ -f "$INPUT_PATH/.gitignore" ] && command -v git >/dev/null 2>&1; then
    USE_GITIGNORE=true
fi

# Create the transient directory if it does not exist
if [ ! -d "$TRANSIENT_DIR" ]; then
    mkdir -p "$TRANSIENT_DIR"
    echo "Created directory: $TRANSIENT_DIR"
fi

# Initialize the output file
if [ ! -f "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
    echo "Created output file: $OUTPUT_FILE"
else
    echo "Output file already exists: $OUTPUT_FILE"
fi

# Function to check if a file was already added
file_already_added() {
    local file="$1"
    grep -q "here is $file:" "$OUTPUT_FILE"
}

# Function to check if a file or directory is ignored by .gitignore
is_ignored_by_gitignore() {
    local path="$1"
    if $USE_GITIGNORE; then
        git -C "$INPUT_PATH" check-ignore "$path" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Iterate over the specified file types
FILE_EXTENSIONS=("*.txt" "*.md" "*.py" "*.yaml" "*.template" "*.toml" "Makefile")
FILES_ADDED=0
FILES_PROCESSED=0

for EXT in "${FILE_EXTENSIONS[@]}"; do
    find "$INPUT_PATH" -type f -name "$EXT" ! -name ".*" | while read -r FILE; do
        FILEPATH=$(realpath "$FILE")

        # Skip files in the transient directory or ignored by .gitignore
        if [[ "$FILEPATH" == *"$TRANSIENT_DIR"* ]] || is_ignored_by_gitignore "$FILEPATH"; then
            continue
        fi

        ((FILES_PROCESSED++))

        if file_already_added "$FILEPATH"; then
            echo "Skipping already added file: $FILEPATH"
            continue
        fi

        echo "Processing: $FILEPATH"

        FILENAME=$(basename "$FILE")
        echo "here is $FILEPATH:" >> "$OUTPUT_FILE"
        echo "<$FILENAME>" >> "$OUTPUT_FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo "</$FILENAME>" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        ((FILES_ADDED++))
    done

done

if [ $FILES_PROCESSED -eq 0 ]; then
    echo "No files found matching the specified criteria. Exiting."
    exit 0
fi

if [ $FILES_ADDED -eq 0 ]; then
    echo "No new files to add. Exiting."
    exit 0
else
    echo "All files aggregated into: $OUTPUT_FILE"
    exit 0
fi

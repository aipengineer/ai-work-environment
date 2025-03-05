#!/bin/bash

# Name: aggregate_text_files.sh
# Description: Aggregates non-hidden text files in a given directory and its subdirectories into a single timestamped file, respecting .gitignore.
#              This refactored version omits processing anything under _transient-files and avoids recursing into already-aggregated files.

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

# Initialize the output file if it doesn't exist
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

# Define file extensions to search for (fixed array syntax)
FILE_EXTENSIONS=("*.txt" "*.md" "*.py" "*.yaml" "*.template" "*.toml" "Makefile" "*.ts" "*.tsx" "*.mdx" "*.js" "*.jsx")
FILES_ADDED=0
FILES_PROCESSED=0

# Loop over each file extension and use find to exclude transient files
for EXT in "${FILE_EXTENSIONS[@]}"; do
    while IFS= read -r FILE; do
        FILEPATH=$(realpath "$FILE")
        
        # Skip if file is in the transient directory or ignored by .gitignore
        if [[ "$FILEPATH" == "$TRANSIENT_DIR"* ]] || is_ignored_by_gitignore "$FILEPATH"; then
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
    done < <(find "$INPUT_PATH" -type f -name "$EXT" ! -path "${TRANSIENT_DIR}/*" ! -name ".*")
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

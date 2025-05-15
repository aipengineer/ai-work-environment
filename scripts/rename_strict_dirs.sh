#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

INPUT_PATH="${1%/}"

if [[ ! -d "$INPUT_PATH" ]]; then
  echo "Error: Provided path '$INPUT_PATH' is not a valid directory."
  exit 1
fi

# Function to map old names to renamed names
map_dir_name() {
  case "$1" in
    raw) echo "00-raw" ;;
    edited) echo "01-edited" ;;
    processed) echo "02-processed" ;;
    publishable) echo "03-publishable" ;;
    *) return 1 ;;
  esac
}

# Canonical directory names
CANON_NAMES=("00-raw" "01-edited" "02-processed" "03-publishable")

# Safely initialize empty list of touched parents
touched_parents=""

# Step 1: Rename matching directories
find "$INPUT_PATH" -type d | while read -r dir; do
  base_name=$(basename "$dir")
  if new_name=$(map_dir_name "$base_name" 2>/dev/null); then
    parent_dir=$(dirname "$dir")
    new_path="$parent_dir/$new_name"

    if [[ "$dir" != "$new_path" && ! -e "$new_path" ]]; then
      echo "Renaming '$dir' -> '$new_path'"
      mv "$dir" "$new_path"
    fi

    # Append to touched_parents list with newline
    touched_parents="${touched_parents}"$'\n'"$parent_dir"
  fi
done

# Deduplicate and clean up list
if [[ -n "$touched_parents" ]]; then
  echo "$touched_parents" | sort -u | while read -r parent; do
    # Skip empty lines
    [[ -z "$parent" ]] && continue

    found=0
    missing=()

    for name in "${CANON_NAMES[@]}"; do
      if [[ -d "$parent/$name" ]]; then
        found=1
      else
        missing+=("$name")
      fi
    done

    if [[ $found -eq 1 ]]; then
      for name in "${missing[@]}"; do
        echo "Creating missing directory: $parent/$name"
        mkdir -p "$parent/$name"
      done
    fi
  done
fi

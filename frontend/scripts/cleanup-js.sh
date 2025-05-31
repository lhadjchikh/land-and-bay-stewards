#!/bin/bash

# This script removes JavaScript files that have TypeScript equivalents

# Find all .ts and .tsx files
ts_files=$(find src -name "*.ts" -o -name "*.tsx")

# For each TypeScript file, check if a corresponding JavaScript file exists
for ts_file in $ts_files; do
  # Get the base path without extension
  base_path="${ts_file%.*}"

  # Check if .js file exists
  js_file="${base_path}.js"
  if [ -f "$js_file" ]; then
    echo "Removing $js_file (replaced by TypeScript)"
    rm "$js_file"
  fi

  # Check if .jsx file exists
  jsx_file="${base_path}.jsx"
  if [ -f "$jsx_file" ]; then
    echo "Removing $jsx_file (replaced by TypeScript)"
    rm "$jsx_file"
  fi
done

echo "Cleanup complete!"

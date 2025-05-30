#!/bin/bash
set -e

# Run Python linters
echo "Running black..."
poetry run black .

echo "Running ruff..."
poetry run ruff check .

# Run YAML linter
echo "Running yamllint..."
poetry run yamllint -f colored ../.github/workflows/ ../terraform

# Run Markdown linter
echo "Running mdformat..."
poetry run mdformat ../README.md
for file in $(find .. -name "*.md" -type f -not -path "../frontend/node_modules/*" -not -path "../backend/.venv/*"); do
    echo "Formatting $file"
    poetry run mdformat "$file"
done

# Check for terraform binary
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Skipping terraform lint checks."
else
    # Run Terraform linters
    echo "Running terraform fmt..."
    cd ../terraform
    terraform fmt -check -recursive || echo "Terraform format check failed. Run 'terraform fmt -recursive' to fix."
    
    # Check for tflint binary
    if ! command -v tflint &> /dev/null; then
        echo "TFLint is not installed. Skipping tflint checks."
    else
        echo "Running tflint..."
        tflint --init
        tflint --recursive
    fi
    cd -
fi

echo "All linters completed successfully!"
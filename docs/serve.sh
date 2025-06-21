#!/bin/bash
# Local documentation development server
# This script serves the documentation locally for development

echo "🚀 Starting local documentation server..."

# Check if mkdocs is installed
if ! command -v mkdocs &>/dev/null; then
  echo "📦 Installing MkDocs and dependencies..."
  pip install -r docs/requirements.txt
fi

echo "📚 Serving documentation at http://localhost:8000"
echo "✨ The site will auto-reload when you make changes"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Serve the documentation with live reload
mkdocs serve

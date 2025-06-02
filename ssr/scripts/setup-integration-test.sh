#!/bin/bash
# setup-integration-test.sh - Set up SSR integration testing

set -e

echo "🔧 Setting up SSR Integration Test..."

# Make sure we have the required directories
mkdir -p tests

# Create the test files in the ssr/tests directory
echo "📁 Creating integration test files in tests/..."

# Create the test files
cat >tests/test-ssr-integration.js <<'EOF'
// Integration test content will be here - copy from the artifact above
EOF

cat >tests/test-ssr-integration-simple.js <<'EOF'
// Simple integration test content will be here - copy from the artifact above
EOF

echo "⚠️  Please copy the test content from the test artifacts to the files in tests/"

# Check if there's a package.json in the ssr directory
if [ ! -f "package.json" ]; then
  echo "⚠️  No package.json found. Please create one first."
  exit 1
fi

# Update package.json to include test scripts if not already present
echo "📦 Updating package.json with test scripts..."

# Check if jq is installed
if ! command -v jq &>/dev/null; then
  echo "⚠️  jq is not installed. Please install jq or manually add test scripts to package.json."
  echo "   Add these to the scripts section:"
  echo '   "test": "node tests/test-ssr-integration.js",'
  echo '   "test:simple": "node tests/test-ssr-integration-simple.js",'
  echo '   "test:ci": "node tests/test-ssr-integration-simple.js"'
else
  # Add test scripts using jq if not already present
  if ! grep -q '"test"' package.json; then
    jq '.scripts.test = "node tests/test-ssr-integration.js"' package.json >package.json.tmp && mv package.json.tmp package.json
  fi

  if ! grep -q '"test:simple"' package.json; then
    jq '.scripts."test:simple" = "node tests/test-ssr-integration-simple.js"' package.json >package.json.tmp && mv package.json.tmp package.json
  fi

  if ! grep -q '"test:ci"' package.json; then
    jq '.scripts."test:ci" = "node tests/test-ssr-integration-simple.js"' package.json >package.json.tmp && mv package.json.tmp package.json
  fi
fi

# Install node-fetch if needed
echo "📦 Installing test dependencies..."
if ! grep -q '"node-fetch"' package.json; then
  npm install --save-dev node-fetch@2
else
  echo "node-fetch already in dependencies, skipping"
fi

# Create a test runner script
cat >scripts/run-integration-test.sh <<'EOF'
#!/bin/bash
# Local test runner

set -e

cd "$(dirname "$0")/.."
BASE_DIR="$(pwd)"
PROJECT_DIR="$(cd .. && pwd)"

echo "🚀 Starting local integration test..."

# Start services
echo "🐳 Starting Docker services..."
cd "$PROJECT_DIR"
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 45

# Create test data
echo "📊 Creating test data..."
docker compose exec -T api bash -c 'cd /app/backend && python scripts/create_test_data.py' || echo "Warning: Test data creation may have failed"

# Run tests
echo "🧪 Running integration tests..."
cd "$BASE_DIR"
npm run test

# Cleanup
echo "🧹 Cleaning up..."
cd "$PROJECT_DIR"
docker compose down

echo "✅ Integration test completed!"
EOF

chmod +x scripts/run-integration-test.sh

echo "✅ Integration test setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy the integration test content to tests/test-*.js files"
echo "2. Make sure your application is properly set up in this directory"
echo "3. Run locally: ./scripts/run-integration-test.sh"
echo "4. GitHub Actions workflows have already been updated"
echo ""
echo "🔍 Tests will verify:"
echo "  ✓ SSR health endpoint"
echo "  ✓ Django API connectivity"
echo "  ✓ Server-side rendering"
echo "  ✓ Load balancer routing"
echo "  ✓ Container communication"
echo "  ✓ Performance basics"

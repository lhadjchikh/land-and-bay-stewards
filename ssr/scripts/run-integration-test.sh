#!/bin/bash
# Local test runner for SSR integration tests

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

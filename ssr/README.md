# Coalition Builder - Server-Side Rendering (SSR)

This directory contains the Next.js application that provides server-side rendering for the Coalition Builder project.

## 📚 Documentation

**For complete documentation, visit: [your-org.github.io/coalition-builder](https://your-org.github.io/coalition-builder/)**

Quick links:

- [SSR Development Guide](../docs/development/ssr.md)
- [Development Setup](../docs/development/setup.md)

## Architecture

This implementation uses Next.js App Router for server-side rendering. Key aspects:

- **App Router**: Uses Next.js 14's App Router architecture
- **API Integration**: Fetches data from the Django backend API
- **Docker Ready**: Optimized for containerized deployment
- **Health Monitoring**: Includes health check and metrics endpoints

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm run start

# Run linting
npm run lint

# Type checking
npm run type-check
```

## Directory Structure

```
/app                   # App Router directory
  /health              # Health check endpoint
    /route.ts          # Health API implementation
  /metrics             # Metrics endpoint
    /route.ts          # Metrics API implementation
  /page.tsx            # Main landing page
  /layout.tsx          # Root layout with metadata
  /globals.css         # Global styles
/lib
  /api.ts              # API client for backend communication
/scripts
  /setup-integration-test.sh  # Setup script for integration tests
  /run-integration-test.sh    # Runner script for integration tests
/tests
  /test-ssr-integration.js        # Comprehensive integration tests
  /test-ssr-integration-simple.js # Simple integration tests
/types
  /index.ts            # TypeScript type definitions
```

## Configuration

Environment variables can be set in `.env` file or via Docker:

- `API_URL`: URL of the Django backend API (server-side only)
- `NEXT_PUBLIC_API_URL`: URL of the API (client-side accessible)
- `PORT`: Port to run the Next.js server on (default: 3000)
- `NODE_ENV`: Environment ('development' or 'production')

## Docker Usage

```bash
# Build the Docker image
docker build -t coalition-ssr .

# Run the container
docker run -p 3000:3000 -e API_URL=http://api:8000 coalition-ssr
```

## Testing

### Running Tests

Integration tests are included in the `tests` directory and can be run using npm scripts:

```bash
# Run comprehensive integration test
npm test

# Run simple integration test
npm run test:simple

# Run tests for CI environment
npm run test:ci
```

You can also run the tests directly:

```bash
# Run simple integration test
node tests/test-ssr-integration-simple.js

# Run comprehensive integration test
node tests/test-ssr-integration.js
```

### Test Scripts

Helper scripts in the `scripts` directory make it easier to set up and run tests:

```bash
# Set up integration tests (creates necessary files and installs dependencies)
./scripts/setup-integration-test.sh

# Run a full integration test with Docker Compose
./scripts/run-integration-test.sh
```

## Deployment

This application is deployed to AWS ECS alongside the Django backend. Both containers run within the same task definition, with routing handled by an Application Load Balancer.

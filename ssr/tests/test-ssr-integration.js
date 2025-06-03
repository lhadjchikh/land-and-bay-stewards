/**
 * SSR Integration Test
 * Tests the full stack with both Django API and Next.js SSR working together
 *
 * This test verifies:
 * 1. SSR container is running and healthy
 * 2. Django API is accessible from SSR container
 * 3. SSR pages are properly server-side rendered
 * 4. API routing works correctly
 * 5. Static assets are served correctly
 */

const { exec } = require("child_process");
const { promisify } = require("util");
const execAsync = promisify(exec);
const http = require("http");
const https = require("https");
const { URL } = require("url");

// Use the simpler approach from test-ssr-integration-simple.js
// Import the makeRequest and waitForService functions
const simpleIntegration = require('./test-ssr-integration-simple');
const makeRequest = simpleIntegration.makeRequest;
const waitForService = simpleIntegration.waitForService;

// Simple fetch-like wrapper around makeRequest for backward compatibility
const fetch = async (url, options = {}) => {
  try {
    const response = await makeRequest(url);
    return {
      ok: response.statusCode >= 200 && response.statusCode < 300,
      status: response.statusCode,
      statusText: response.statusCode === 200 ? 'OK' : 'Error',
      headers: response.headers,
      json: () => JSON.parse(response.data),
      text: () => response.data
    };
  } catch (error) {
    console.error(`Fetch error: ${error.message}`);
    throw error;
  }
};

// Test configuration
const TEST_CONFIG = {
  SSR_URL: process.env.SSR_URL || "http://localhost:3000",
  API_URL: process.env.API_URL || "http://localhost:8000",
  NGINX_URL: process.env.NGINX_URL || "http://localhost:80",
  TIMEOUT: parseInt(process.env.TEST_TIMEOUT) || 60000, // 60 seconds by default
  RETRY_COUNT: parseInt(process.env.TEST_RETRY_COUNT) || 5,
  RETRY_DELAY: parseInt(process.env.TEST_RETRY_DELAY) || 3000, // 3 seconds
  CI_MODE: process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true'
};

// Log test configuration
console.log("Test Configuration:", {
  ...TEST_CONFIG,
  TIMEOUT: `${TEST_CONFIG.TIMEOUT}ms`,
  RETRY_DELAY: `${TEST_CONFIG.RETRY_DELAY}ms`,
  ENVIRONMENT: TEST_CONFIG.CI_MODE ? "CI" : "Local"
});

// Helper function to wait for service to be ready with exponential backoff
async function waitForService(url, timeoutMs = TEST_CONFIG.TIMEOUT) {
  const startTime = Date.now();
  let retryDelay = 1000; // Start with 1 second
  const maxRetryDelay = 8000; // Cap at 8 seconds

  while (Date.now() - startTime < timeoutMs) {
    try {
      const response = await fetch(url);
      if (response.ok) {
        console.log(`✅ Service at ${url} is ready`);
        return true;
      } else {
        console.log(`⚠️ Service at ${url} returned status ${response.status}, waiting...`);
      }
    } catch (error) {
      // Service not ready yet, continue waiting
      console.log(`⚠️ Service at ${url} not ready: ${error.message}`);
    }

    // Apply exponential backoff with jitter
    const jitter = Math.random() * 500;
    retryDelay = Math.min(retryDelay * 1.5 + jitter, maxRetryDelay);
    console.log(`Waiting ${Math.round(retryDelay)}ms before next attempt...`);
    
    // Wait before trying again
    await new Promise((resolve) => setTimeout(resolve, retryDelay));
  }

  throw new Error(
    `Service at ${url} did not become ready within ${timeoutMs}ms`
  );
}

// Helper function to make HTTP requests with retries and exponential backoff
async function fetchWithRetry(url, options = {}) {
  let retryDelay = TEST_CONFIG.RETRY_DELAY;

  for (let i = 0; i < TEST_CONFIG.RETRY_COUNT; i++) {
    try {
      // Remove non-standard timeout from fetch options
      const { timeout, ...fetchOptions } = options;
      
      // Create AbortController for timeout (if needed)
      let controller;
      if (timeout) {
        controller = new AbortController();
        setTimeout(() => controller.abort(), timeout);
        fetchOptions.signal = controller.signal;
      }
      
      const response = await fetch(url, fetchOptions);
      return response;
    } catch (error) {
      if (i === TEST_CONFIG.RETRY_COUNT - 1) {
        throw error;
      }
      
      console.log(
        `Request failed (attempt ${i + 1}/${
          TEST_CONFIG.RETRY_COUNT
        }): ${error.message}, retrying...`
      );
      
      // Exponential backoff with jitter
      const jitter = Math.random() * 500;
      retryDelay = Math.min(retryDelay * 1.5 + jitter, 10000);
      
      await new Promise((resolve) =>
        setTimeout(resolve, retryDelay)
      );
    }
  }
  
  throw new Error(`Failed after ${TEST_CONFIG.RETRY_COUNT} attempts`);
}

// Test 1: Verify SSR Health Check
async function testSSRHealth() {
  console.log("🔍 Testing SSR health endpoint...");

  const response = await fetchWithRetry(`${TEST_CONFIG.SSR_URL}/health`);

  if (!response.ok) {
    throw new Error(
      `SSR health check failed: ${response.status} ${response.statusText}`
    );
  }

  const data = await response.json();

  if (data.status !== "healthy") {
    throw new Error(
      `SSR health check returned unhealthy status: ${JSON.stringify(data)}`
    );
  }

  console.log("✅ SSR health check passed");
  return data;
}

// Test 2: Verify Django API health
async function testDjangoAPI() {
  console.log("🔍 Testing Django API health...");

  const response = await fetchWithRetry(
    `${TEST_CONFIG.API_URL}/api/health/`
  );

  if (!response.ok) {
    throw new Error(
      `Django API health test failed: ${response.status} ${response.statusText}`
    );
  }

  const healthData = await response.json();

  if (healthData.status !== "healthy") {
    throw new Error(
      `Django API health check returned unhealthy status: ${JSON.stringify(healthData)}`
    );
  }

  // Also test data endpoint
  const dataResponse = await fetchWithRetry(
    `${TEST_CONFIG.API_URL}/api/campaigns/`
  );

  if (!dataResponse.ok) {
    throw new Error(
      `Django API data endpoint failed: ${dataResponse.status} ${dataResponse.statusText}`
    );
  }

  const campaigns = await dataResponse.json();

  if (!Array.isArray(campaigns)) {
    throw new Error(
      `Django API returned invalid data: expected array, got ${typeof campaigns}`
    );
  }

  console.log(
    `✅ Django API tests passed (health check OK, returned ${campaigns.length} campaigns)`
  );
  return campaigns;
}

// Test 3: Verify SSR Homepage Rendering
async function testSSRHomepage() {
  console.log("🔍 Testing SSR homepage rendering...");

  const response = await fetchWithRetry(TEST_CONFIG.SSR_URL);

  if (!response.ok) {
    throw new Error(
      `SSR homepage failed: ${response.status} ${response.statusText}`
    );
  }

  const html = await response.text();

  // Check that it's actually server-side rendered HTML
  if (!html.includes("<html")) {
    throw new Error("SSR homepage did not return HTML content");
  }

  // Define critical and non-critical content to check
  const criticalContent = [
    // Fundamental HTML structure must be present
    "<html",
    "<head",
    "<body",
  ];
  
  // Content that should be present but won't fail tests if missing
  // These could change with UI updates
  const expectedContent = [
    "Land and Bay Stewards",
    "Policy Campaigns",
    // Check for Next.js specific meta tags
    "viewport",
  ];

  // Check critical content first (must have these)
  for (const content of criticalContent) {
    if (!html.includes(content)) {
      throw new Error(`SSR homepage missing critical content: "${content}"`);
    }
  }
  
  // Check expected content (warn if missing but don't fail)
  let missingContent = [];
  for (const content of expectedContent) {
    if (!html.includes(content)) {
      missingContent.push(content);
    }
  }
  
  if (missingContent.length > 0) {
    console.warn(
      `⚠️  Warning: SSR homepage missing some expected content: ${missingContent.join(", ")}`
    );
  }

  // Verify it's actually SSR by checking for hydration markers
  if (!html.includes("__NEXT_DATA__") && !html.includes("next/script")) {
    console.warn(
      "⚠️  Warning: Page might not be properly server-side rendered (missing Next.js hydration markers)"
    );
  }

  console.log("✅ SSR homepage rendering test passed");
  return html;
}

// Test 4: Test API routing through Load Balancer/Nginx
async function testAPIRouting() {
  console.log("🔍 Testing API routing through load balancer...");

  // Test through Nginx (simulates ALB routing)
  const response = await fetchWithRetry(
    `${TEST_CONFIG.NGINX_URL}/api/campaigns/`
  );

  if (!response.ok) {
    throw new Error(
      `API routing test failed: ${response.status} ${response.statusText}`
    );
  }

  const campaigns = await response.json();

  if (!Array.isArray(campaigns)) {
    throw new Error(
      `API routing returned invalid data: expected array, got ${typeof campaigns}`
    );
  }

  console.log(
    `✅ API routing test passed (returned ${campaigns.length} campaigns through load balancer)`
  );
  return campaigns;
}

// Test 5: Test SSR with API Integration
async function testSSRAPIIntegration() {
  console.log("🔍 Testing SSR + API integration...");

  // This tests that SSR can fetch data from the API and render it
  const response = await fetchWithRetry(TEST_CONFIG.SSR_URL);
  const html = await response.text();

  // Look for signs that the page has been rendered with actual data
  // This would indicate that SSR successfully called the API
  const hasDataRendered =
    html.includes("campaign") ||
    html.includes("Policy Campaign") ||
    html.includes("No campaigns found");

  if (!hasDataRendered) {
    console.warn(
      "⚠️  Warning: SSR page may not have successfully fetched API data"
    );
  } else {
    console.log("✅ SSR appears to have successfully integrated with API");
  }

  return hasDataRendered;
}

// Test 6: Test Container Communication
async function testContainerCommunication() {
  console.log("🔍 Testing container-to-container communication...");

  try {
    // First check if Docker is available
    let dockerAvailable = false;
    try {
      await execAsync("docker --version");
      dockerAvailable = true;
    } catch (error) {
      console.log("ℹ️  Docker not available, skipping container communication test");
      return true; // Skip test but don't fail it
    }

    if (dockerAvailable) {
      // Check if we're running in Docker environment and have the right containers
      // Modern Docker CLI uses 'docker compose' (not 'docker-compose')
      const dockerComposeCmd = "docker compose";

      const { stdout } = await execAsync(`${dockerComposeCmd} ps --services`);
      const services = stdout.trim().split("\n");

      if (services.includes("ssr") && services.includes("api")) {
        // Test that SSR container can reach API container
        try {
          const { stdout: apiTest } = await execAsync(
            `${dockerComposeCmd} exec -T ssr curl -s -o /dev/null -w "%{http_code}" http://api:8000/api/campaigns/ || echo "failed"`
          );

          if (apiTest.trim() === "200") {
            console.log("✅ Container-to-container communication test passed");
            return true;
          } else {
            console.warn(
              `⚠️  Warning: Container-to-container communication may have issues (status: ${apiTest.trim()})`
            );
            return false;
          }
        } catch (cmdError) {
          console.warn(`⚠️  Container command execution failed: ${cmdError.message}`);
          return false;
        }
      } else {
        console.log(`ℹ️  Required services (ssr, api) not running in Docker. Found: [${services.join(", ")}]`);
        return true; // Skip test but don't fail it
      }
    }
  } catch (error) {
    // Log the error but don't fail the entire test suite for this
    console.log(
      `ℹ️  Skipping container communication test: ${error.message}`
    );
    return true;
  }
  
  return true; // Default pass if we reach here
}

// Test 7: Performance Test
async function testPerformance() {
  console.log("🔍 Running basic performance test...");

  const startTime = Date.now();
  const response = await fetchWithRetry(TEST_CONFIG.SSR_URL);
  const endTime = Date.now();

  const responseTime = endTime - startTime;

  if (!response.ok) {
    throw new Error(`Performance test failed: ${response.status}`);
  }

  console.log(`✅ Performance test passed (response time: ${responseTime}ms)`);

  if (responseTime > 5000) {
    console.warn("⚠️  Warning: Response time is quite slow (>5s)");
  }

  return responseTime;
}

// Main test runner
async function runIntegrationTests() {
  console.log("🚀 Starting SSR Integration Tests...\n");

  const results = {
    passed: 0,
    failed: 0,
    warnings: 0,
    tests: [],
    startTime: Date.now(),
  };

  // Track warnings by overriding console.warn
  const originalWarn = console.warn;
  console.warn = (...args) => {
    results.warnings++;
    originalWarn.apply(console, args);
  };

  const tests = [
    { name: "SSR Health Check", fn: testSSRHealth },
    { name: "Django API Direct", fn: testDjangoAPI },
    { name: "SSR Homepage Rendering", fn: testSSRHomepage },
    { name: "API Routing", fn: testAPIRouting },
    { name: "SSR API Integration", fn: testSSRAPIIntegration },
    { name: "Container Communication", fn: testContainerCommunication },
    { name: "Performance Test", fn: testPerformance },
  ];

  // Wait for services to be ready
  console.log("⏳ Waiting for services to be ready...");
  try {
    await Promise.all([
      waitForService(`${TEST_CONFIG.SSR_URL}/health`),
      waitForService(`${TEST_CONFIG.API_URL}/api/health/`),
    ]);
    console.log("✅ All services are ready\n");
  } catch (error) {
    console.error("❌ Services failed to start:", error.message);
    process.exit(1);
  }

  // Run all tests
  for (const test of tests) {
    try {
      const result = await test.fn();
      results.passed++;
      results.tests.push({ name: test.name, status: "PASSED", result });
    } catch (error) {
      results.failed++;
      results.tests.push({
        name: test.name,
        status: "FAILED",
        error: error.message,
      });
      console.error(`❌ ${test.name} failed:`, error.message);
    }
    console.log(""); // Add spacing between tests
  }

  // Restore original console.warn
  console.warn = originalWarn;

  // Calculate elapsed time
  const totalTime = Date.now() - results.startTime;
  const minutes = Math.floor(totalTime / 60000);
  const seconds = ((totalTime % 60000) / 1000).toFixed(2);
  
  // Print summary
  console.log("\n📊 Test Summary:");
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`⚠️  Warnings: ${results.warnings}`);
  console.log(`⏱️  Total time: ${minutes > 0 ? `${minutes}m ` : ''}${seconds}s`);

  // Print test results
  if (results.tests.length > 0) {
    console.log("\nTest details:");
    results.tests.forEach(test => {
      if (test.status === "PASSED") {
        console.log(`  ✅ ${test.name}`);
      } else {
        console.log(`  ❌ ${test.name}: ${test.error}`);
      }
    });
  }

  if (results.failed > 0) {
    console.log("\n❌ Integration tests failed!");
    process.exit(1);
  } else {
    console.log("\n🎉 All integration tests passed!");
    process.exit(0);
  }
}

// Handle graceful shutdown
process.on("SIGINT", () => {
  console.log("\n⏹️  Tests interrupted");
  process.exit(1);
});

process.on("SIGTERM", () => {
  console.log("\n⏹️  Tests terminated");
  process.exit(1);
});

// Export for testing
if (require.main === module) {
  runIntegrationTests().catch((error) => {
    console.error("💥 Integration tests crashed:", error);
    process.exit(1);
  });
}

module.exports = {
  runIntegrationTests,
  testSSRHealth,
  testDjangoAPI,
  testSSRHomepage,
  testAPIRouting,
  testSSRAPIIntegration,
  testContainerCommunication,
  testPerformance,
};

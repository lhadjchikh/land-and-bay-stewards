/**
 * Lenient health check script for Docker container
 *
 * This script checks the health of the Next.js SSR service without
 * requiring immediate Django API connectivity during startup.
 */

const http = require("http");

// Configuration
const options = {
  hostname: "localhost",
  port: process.env.PORT || 3000,
  path: "/health",
  method: "GET",
  timeout: 3000,
  headers: {
    Accept: "application/json",
  },
};

// Execute health check
const req = http.request(options, (res) => {
  let data = "";

  // Collect response data
  res.on("data", (chunk) => {
    data += chunk;
  });

  // Process the complete response
  res.on("end", () => {
    if (res.statusCode === 200) {
      try {
        // Parse the JSON response
        const healthData = JSON.parse(data);

        // Check if the SSR service itself is healthy
        // Don't require immediate API connectivity during container startup
        if (healthData.status === "healthy") {
          console.log("✅ Health check passed - SSR service is healthy");
          process.exit(0);
        } else {
          console.log(
            `❌ Health check failed - SSR Status: ${healthData.status}`,
          );
          process.exit(1);
        }
      } catch (e) {
        console.log(
          `❌ Health check failed - Invalid JSON response: ${e.message}`,
        );
        process.exit(1);
      }
    } else {
      console.log(`❌ Health check failed with status: ${res.statusCode}`);
      process.exit(1);
    }
  });
});

// Handle connection errors
req.on("error", (err) => {
  console.log(`❌ Health check failed: ${err.message}`);
  process.exit(1);
});

// Handle timeouts
req.on("timeout", () => {
  console.log("❌ Health check timed out");
  req.destroy();
  process.exit(1);
});

// Send the request
req.end();

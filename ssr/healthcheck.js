/**
 * Health check script for Docker container
 *
 * This script checks the health of the Next.js SSR service by
 * making a request to the dedicated health endpoint.
 */

const http = require("http");
const os = require("os");

// Configuration
const options = {
  hostname: os.hostname() || "localhost",
  port: parseInt(process.env.PORT) || 3000,
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

        // Check if the status is healthy and API is connected
        if (
          healthData.status === "healthy" &&
          healthData.api?.status === "connected"
        ) {
          console.log("✅ Health check passed - API connection verified");
          process.exit(0);
        } else {
          console.error(
            `❌ Health check failed - Status: ${healthData.status}, API: ${healthData.api?.status}`,
          );
          process.exit(1);
        }
      } catch (e) {
        console.error(
          `❌ Health check failed - Invalid JSON response: ${e.message}`,
        );
        process.exit(1);
      }
    } else {
      console.error(`❌ Health check failed with status: ${res.statusCode}`);
      process.exit(1);
    }
  });
});

// Handle connection errors
req.on("error", (err) => {
  console.error(`❌ Health check failed: ${err.message}`);
  process.exit(1);
});

// Handle timeouts
req.on("timeout", () => {
  console.error("❌ Health check timed out");
  req.destroy();
  process.exit(1);
});

// Send the request
req.end();

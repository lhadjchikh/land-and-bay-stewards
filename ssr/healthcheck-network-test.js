/**
 * Network connectivity test for SSR to Django API communication
 * Tests multiple approaches to find working connection method
 */

const http = require("http");
const os = require("os");

// Get the current hostname/IP
const hostname = os.hostname();
console.log(`🔍 Container hostname: ${hostname}`);

// Test different API URLs
const apiUrls = [
  "http://localhost:8000",
  `http://${hostname}:8000`,
  "http://127.0.0.1:8000",
];

async function testApiConnection(apiUrl) {
  return new Promise((resolve) => {
    console.log(`🚀 Testing API connection to: ${apiUrl}`);

    const url = new URL(apiUrl);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: "/api/health/",
      method: "GET",
      timeout: 5000,
      headers: {
        Accept: "application/json",
      },
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });

      res.on("end", () => {
        if (res.statusCode === 200) {
          console.log(`✅ SUCCESS: ${apiUrl} responded with 200`);
          resolve({
            success: true,
            url: apiUrl,
            status: res.statusCode,
            data: data.substring(0, 100),
          });
        } else {
          console.log(`❌ FAILED: ${apiUrl} responded with ${res.statusCode}`);
          resolve({ success: false, url: apiUrl, status: res.statusCode });
        }
      });
    });

    req.on("error", (err) => {
      console.log(`❌ ERROR: ${apiUrl} - ${err.message}`);
      resolve({ success: false, url: apiUrl, error: err.message });
    });

    req.on("timeout", () => {
      console.log(`⏰ TIMEOUT: ${apiUrl}`);
      req.destroy();
      resolve({ success: false, url: apiUrl, error: "timeout" });
    });

    req.end();
  });
}

async function testAllConnections() {
  console.log(`🔍 Testing API connectivity from SSR container...`);

  const results = [];
  for (const apiUrl of apiUrls) {
    const result = await testApiConnection(apiUrl);
    results.push(result);
  }

  console.log(`\n📊 Results summary:`);
  results.forEach((result) => {
    const status = result.success ? "✅ SUCCESS" : "❌ FAILED";
    console.log(`${status}: ${result.url} - ${result.status || result.error}`);
  });

  // If any connection succeeded, the overall health check passes
  const anySuccess = results.some((r) => r.success);
  if (anySuccess) {
    console.log(`\n🎉 At least one API connection method works!`);
    process.exit(0);
  } else {
    console.log(`\n💥 All API connection methods failed`);
    process.exit(1);
  }
}

// Also test SSR service itself
async function testSsrService() {
  return new Promise((resolve) => {
    const options = {
      hostname: "localhost",
      port: 3000,
      path: "/health",
      method: "GET",
      timeout: 3000,
    };

    const req = http.request(options, (res) => {
      if (res.statusCode === 200) {
        console.log(`✅ SSR service is responding`);
        resolve(true);
      } else {
        console.log(`❌ SSR service error: ${res.statusCode}`);
        resolve(false);
      }
    });

    req.on("error", (err) => {
      console.log(`❌ SSR service error: ${err.message}`);
      resolve(false);
    });

    req.on("timeout", () => {
      console.log(`⏰ SSR service timeout`);
      req.destroy();
      resolve(false);
    });

    req.end();
  });
}

async function main() {
  console.log(`🏥 Network connectivity health check starting...`);

  // First test SSR service
  const ssrWorking = await testSsrService();

  if (!ssrWorking) {
    console.log(`💥 SSR service is not responding - failing health check`);
    process.exit(1);
  }

  // Then test API connections
  await testAllConnections();
}

main().catch((err) => {
  console.error(`💥 Unexpected error: ${err.message}`);
  process.exit(1);
});

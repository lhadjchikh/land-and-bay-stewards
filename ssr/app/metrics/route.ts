// ssr/app/metrics/route.ts
import { NextResponse } from "next/server";

// Simple in-memory metrics tracker
// Note: In a production environment, consider using a proper metrics library
const metrics = {
  requestCount: 0,
  errorCount: 0,
  startTime: Date.now(),
  lastRequest: Date.now(),
};

export async function GET() {
  // Update metrics
  metrics.requestCount++;
  metrics.lastRequest = Date.now();

  // Calculate uptime
  const uptime = Math.floor((Date.now() - metrics.startTime) / 1000);
  const hours = Math.floor(uptime / 3600);
  const minutes = Math.floor((uptime % 3600) / 60);
  const seconds = uptime % 60;
  
  // Get memory usage
  const memoryUsage = process.memoryUsage();
  
  return NextResponse.json({
    uptime: {
      seconds: uptime,
      formatted: `${hours}h ${minutes}m ${seconds}s`,
    },
    memory: {
      rss: `${Math.round(memoryUsage.rss / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)}MB`,
      external: `${Math.round(memoryUsage.external / 1024 / 1024)}MB`,
    },
    requests: {
      total: metrics.requestCount,
      errors: metrics.errorCount,
    },
    system: {
      platform: process.platform,
      nodeVersion: process.version,
      env: process.env.NODE_ENV || "development",
    },
    timestamp: new Date().toISOString(),
  }, {
    headers: {
      'Cache-Control': 'no-store, max-age=0',
    }
  });
}

// Handle errors centrally in your app
export function registerErrorForMetrics() {
  metrics.errorCount++;
}
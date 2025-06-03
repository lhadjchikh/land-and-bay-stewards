// ssr/app/metrics/route.ts
import { NextResponse } from "next/server";
import metrics from "@/lib/metrics";

export async function GET() {
  // Update request metrics
  metrics.incrementRequestCount();
  
  return NextResponse.json({
    uptime: metrics.getUptime(),
    memory: metrics.getMemoryUsage(),
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
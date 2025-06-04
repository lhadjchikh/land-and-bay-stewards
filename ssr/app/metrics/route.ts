// ssr/app/metrics/route.ts
import { NextResponse } from "next/server";
import metrics from "@/lib/metrics";

export async function GET() {
  // Increment request counter
  metrics.incrementRequestCount();

  // Return metrics data
  return NextResponse.json(
    {
      requestCount: metrics.requestCount,
      errorCount: metrics.errorCount,
      uptime: metrics.getUptime(),
      memory: metrics.getMemoryUsage(),
      lastRequest: new Date(metrics.lastRequest).toISOString(),
      timestamp: new Date().toISOString(),
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store, max-age=0",
      },
    },
  );
}

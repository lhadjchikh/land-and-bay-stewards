// ssr/app/health/route.ts
import { NextResponse } from "next/server";
import { apiClient } from "@/lib/api";
import metrics, { registerError } from "@/lib/metrics";

export async function GET() {
  const startTime = Date.now();

  try {
    // Real health check - attempt to connect to the API
    let apiStatus = "unknown";
    let apiResponseTime = 0;

    try {
      const apiCheckStart = Date.now();
      await apiClient.healthCheck();
      apiResponseTime = Date.now() - apiCheckStart;
      apiStatus = "connected";
    } catch (error) {
      apiStatus = "disconnected";
      registerError();
      console.error("Health check API connection failed:", error);
    }

    // Return comprehensive health information
    return NextResponse.json(
      {
        status: "healthy",
        timestamp: new Date().toISOString(),
        uptime: metrics.getUptime(),
        memory: metrics.getMemoryUsage(),
        api: {
          status: apiStatus,
          url: process.env.API_URL || "http://localhost:8000",
          responseTime: `${apiResponseTime}ms`,
        },
        environment: process.env.NODE_ENV || "development",
        responseTime: `${Date.now() - startTime}ms`,
      },
      {
        status: 200,
        headers: {
          "Cache-Control": "no-store, max-age=0",
        },
      },
    );
  } catch (error) {
    registerError();
    return NextResponse.json(
      {
        status: "unhealthy",
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: new Date().toISOString(),
      },
      {
        status: 500,
        headers: {
          "Cache-Control": "no-store, max-age=0",
        },
      },
    );
  }
}

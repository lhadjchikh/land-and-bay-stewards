// ssr/app/health/route.ts
import { NextResponse } from "next/server";
import { apiClient } from "../../lib/api";

export async function GET() {
  const startTime = Date.now();
  const memoryUsage = process.memoryUsage();
  
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
      console.error("Health check API connection failed:", error);
    }

    // Return comprehensive health information
    return NextResponse.json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024),
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        external: Math.round(memoryUsage.external / 1024 / 1024),
      },
      api: {
        status: apiStatus,
        url: process.env.API_URL || "http://localhost:8000",
        responseTime: `${apiResponseTime}ms`,
      },
      environment: process.env.NODE_ENV || "development",
      responseTime: `${Date.now() - startTime}ms`,
    }, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
      }
    });
  } catch (error) {
    return NextResponse.json({
      status: "unhealthy",
      error: error instanceof Error ? error.message : "Unknown error",
      timestamp: new Date().toISOString(),
    }, { 
      status: 500,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
      }
    });
  }
}
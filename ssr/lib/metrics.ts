// ssr/lib/metrics.ts
// A utility module for tracking application metrics

// This is a singleton metrics tracker that can be imported anywhere in the application
export const metrics = {
  // Counter for different types of requests
  requestCount: 0,
  errorCount: 0,

  // Timing
  startTime: Date.now(),
  lastRequest: Date.now(),

  // Methods to update metrics
  incrementRequestCount() {
    this.requestCount++;
    this.lastRequest = Date.now();
  },

  registerError() {
    this.errorCount++;
  },

  // Helper to get uptime info
  getUptime() {
    const uptime = Math.floor((Date.now() - this.startTime) / 1000);
    return {
      seconds: uptime,
      formatted: `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${uptime % 60}s`,
    };
  },

  // Get memory usage info
  getMemoryUsage() {
    const memUsage = process.memoryUsage();
    return {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
      external: `${Math.round(memUsage.external / 1024 / 1024)}MB`,
    };
  },
};

// Utility functions for error handling
export function registerError() {
  metrics.registerError();
}

export function incrementRequest() {
  metrics.incrementRequestCount();
}

// Export default for convenience
export default metrics;

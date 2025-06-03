#!/usr/bin/env python3
"""
Health check script for Docker container.

This script checks the health of the Django backend by
making a request to the dedicated health endpoint.
"""

import http.client
import json
import sys
import time
import os

def perform_health_check():
    """Perform health check and exit with appropriate status."""
    
    # Configuration
    hostname = "localhost"
    port = int(os.environ.get("PORT", 8000))
    path = "/health/"
    timeout = 3  # seconds
    
    try:
        # Connect with timeout
        start_time = time.time()
        conn = http.client.HTTPConnection(hostname, port, timeout=timeout)
        conn.request("GET", path, headers={"Accept": "application/json"})
        
        # Get response
        response = conn.getresponse()
        response_time = time.time() - start_time
        
        # Check status code
        if response.status == 200:
            # Parse response
            data = json.loads(response.read().decode("utf-8"))
            
            # Check if database is healthy
            if data.get("status") == "healthy" and data.get("database", {}).get("status") == "healthy":
                print(f"✅ Health check passed in {response_time:.3f}s - Database connected")
                sys.exit(0)
            else:
                print(f"❌ Health check failed - Status: {data.get('status')}, DB: {data.get('database', {}).get('status')}")
                sys.exit(1)
        else:
            print(f"❌ Health check failed with status code: {response.status}")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
        sys.exit(1)
    finally:
        try:
            conn.close()
        except:
            pass

if __name__ == "__main__":
    perform_health_check()
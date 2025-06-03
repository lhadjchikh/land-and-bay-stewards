#!/usr/bin/env python3
"""
Health check script for Docker container.

This script checks the health of the Django backend by
making a request to the dedicated health endpoint.
"""

import contextlib
import http.client
import json
import logging
import os
import sys
import time


def perform_health_check() -> None:
    """Perform health check and exit with appropriate status."""
    # Configure logging
    logging.basicConfig(format="%(message)s", level=logging.INFO)
    logger = logging.getLogger("healthcheck")

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
            db_status = data.get("database", {}).get("status")
            app_status = data.get("status")

            if app_status == "healthy" and db_status == "healthy":
                msg = f"✅ Health check passed in {response_time:.3f}s - DB connected"
                logger.info(msg)
                sys.exit(0)
            else:
                msg = f"❌ Health check failed - Status: {app_status}, DB: {db_status}"
                logger.error(msg)
                sys.exit(1)
        else:
            logger.error(f"❌ Health check failed with status code: {response.status}")
            sys.exit(1)

    except Exception as e:
        logger.error(f"❌ Health check failed: {str(e)}")
        sys.exit(1)
    finally:
        with contextlib.suppress(Exception):
            conn.close()


if __name__ == "__main__":
    perform_health_check()

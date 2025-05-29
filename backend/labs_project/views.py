import json
import os

from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render


def get_react_assets() -> dict[str, str]:
    """Read React's asset-manifest.json to get the correct filenames with hashes"""
    # First try the Docker path (copied from frontend stage)
    docker_path = os.path.join(
        settings.BASE_DIR,
        "frontend",
        "build",
        "asset-manifest.json",
    )

    # Then try the local development path
    local_path = os.path.join(
        settings.BASE_DIR.parent,
        "frontend",
        "build",
        "asset-manifest.json",
    )

    # Try Docker path first, then local path
    for manifest_path in [docker_path, local_path]:
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
            return {
                "main_js": manifest["files"]["main.js"].replace("/static/", ""),
                "main_css": manifest["files"]["main.css"].replace("/static/", ""),
            }
        except (FileNotFoundError, KeyError):
            continue

    # Fallback if neither path works
    return {
        "main_js": "js/main.js",
        "main_css": "css/main.css",
    }


def home(request: HttpRequest) -> HttpResponse:

    assets = get_react_assets()
    return render(request, "index.html", {"assets": assets})

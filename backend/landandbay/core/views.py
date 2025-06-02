import json
import logging
import os

from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_GET

logger = logging.getLogger(__name__)


def _get_manifest_paths() -> list[str]:
    """Get possible locations for the asset manifest file"""
    return [
        # Docker container path (copied from frontend build)
        os.path.join(settings.STATIC_ROOT, "frontend", "asset-manifest.json"),
        # Local development path in static files
        os.path.join(settings.BASE_DIR, "static", "frontend", "asset-manifest.json"),
        # Frontend build directory (development)
        os.path.join(
            settings.BASE_DIR.parent,
            "frontend",
            "build",
            "asset-manifest.json",
        ),
        # Alternative static location
        os.path.join(
            settings.BASE_DIR,
            "staticfiles",
            "frontend",
            "asset-manifest.json",
        ),
    ]


def _parse_manifest(manifest: dict) -> tuple[str, str]:
    """Parse manifest data to extract main JS and CSS files"""
    files = manifest.get("files", {})
    entrypoints = manifest.get("entrypoints", [])

    main_js = ""
    main_css = ""

    if files:
        # New format: files object with keys
        main_js = files.get("main.js", "")
        main_css = files.get("main.css", "")
    elif entrypoints:
        # Old format: entrypoints array
        for entry in entrypoints:
            if entry.endswith(".js"):
                main_js = entry
            elif entry.endswith(".css"):
                main_css = entry

    return main_js, main_css


def _normalize_asset_paths(main_js: str, main_css: str) -> dict[str, str]:
    """Normalize asset paths for Django static file serving"""
    # Remove /static/ prefix if present since Django will add it
    main_js = main_js.replace("/static/", "").replace("static/", "")
    main_css = main_css.replace("/static/", "").replace("static/", "")

    # Ensure files are in the frontend subdirectory
    if main_js and not main_js.startswith("frontend/"):
        main_js = f"frontend/{main_js}"
    if main_css and not main_css.startswith("frontend/"):
        main_css = f"frontend/{main_css}"

    return {
        "main_js": main_js,
        "main_css": main_css,
    }


def _find_static_files_directly() -> dict[str, str]:
    """Find static files directly in directories when manifest is unavailable"""
    static_dirs = [
        (
            os.path.join(settings.STATIC_ROOT, "frontend")
            if settings.STATIC_ROOT
            else None
        ),
        os.path.join(settings.BASE_DIR, "static", "frontend"),
        os.path.join(settings.BASE_DIR, "staticfiles", "frontend"),
    ]

    for static_dir in static_dirs:
        if static_dir and os.path.exists(static_dir):
            try:
                # Look for JS and CSS files
                js_files = [
                    f
                    for f in os.listdir(static_dir)
                    if f.endswith(".js") and "main" in f
                ]
                css_files = [
                    f
                    for f in os.listdir(static_dir)
                    if f.endswith(".css") and "main" in f
                ]

                if js_files or css_files:
                    return {
                        "main_js": (
                            f"frontend/{js_files[0]}"
                            if js_files
                            else "frontend/js/main.js"
                        ),
                        "main_css": (
                            f"frontend/{css_files[0]}"
                            if css_files
                            else "frontend/css/main.css"
                        ),
                    }
            except (OSError, IndexError):
                continue

    return {}


def get_react_assets() -> dict[str, str]:
    """Read React's asset-manifest.json to get the correct filenames with hashes"""
    # Try to find and parse manifest files
    for manifest_path in _get_manifest_paths():
        try:
            if os.path.exists(manifest_path):
                with open(manifest_path) as f:
                    manifest = json.load(f)

                main_js, main_css = _parse_manifest(manifest)
                if main_js or main_css:
                    return _normalize_asset_paths(main_js, main_css)

        except (FileNotFoundError, KeyError, json.JSONDecodeError) as e:
            logger.debug("Failed to load manifest from %s: %s", manifest_path, e)
            continue

    # Fallback: try to find files directly in static directories
    direct_files = _find_static_files_directly()
    if direct_files:
        return direct_files

    # Final fallback for development
    return {
        "main_js": "frontend/js/main.js",
        "main_css": "frontend/css/main.css",
    }


def home(request: HttpRequest) -> HttpResponse:
    assets = get_react_assets()
    logger.debug("Loading assets: %s", assets)
    return render(request, "index.html", {"assets": assets})


@require_GET
def robots_txt(request: HttpRequest) -> HttpResponse:
    """Serve the robots.txt file to prevent search engine indexing"""
    return HttpResponse("User-agent: *\nDisallow: /\n", content_type="text/plain")

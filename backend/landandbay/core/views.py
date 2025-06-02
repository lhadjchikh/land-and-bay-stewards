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
        os.path.join(settings.STATIC_ROOT, "asset-manifest.json"),
        os.path.join(settings.STATIC_ROOT, "frontend", "asset-manifest.json"),
        # Local development path in static files
        os.path.join(settings.BASE_DIR, "static", "asset-manifest.json"),
        os.path.join(settings.BASE_DIR, "static", "frontend", "asset-manifest.json"),
        # Frontend build directory (development)
        os.path.join(
            settings.BASE_DIR.parent, "frontend", "build", "asset-manifest.json",
        ),
        # Alternative static location
        os.path.join(settings.BASE_DIR, "staticfiles", "asset-manifest.json"),
        os.path.join(
            settings.BASE_DIR, "staticfiles", "frontend", "asset-manifest.json",
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

    # The files should already be in the correct structure from React build
    # Don't add frontend/ prefix since we're copying directly to static root

    return {
        "main_js": main_js,
        "main_css": main_css,
    }


def _find_static_files_directly() -> dict[str, str]:
    """Find static files directly in directories when manifest is unavailable"""
    static_dirs = [
        os.path.join(settings.STATIC_ROOT, "js") if settings.STATIC_ROOT else None,
        os.path.join(settings.STATIC_ROOT, "css") if settings.STATIC_ROOT else None,
        os.path.join(settings.BASE_DIR, "static", "js"),
        os.path.join(settings.BASE_DIR, "static", "css"),
        os.path.join(settings.BASE_DIR, "staticfiles", "js"),
        os.path.join(settings.BASE_DIR, "staticfiles", "css"),
    ]

    js_file = ""
    css_file = ""

    for static_dir in static_dirs:
        if static_dir and os.path.exists(static_dir):
            try:
                if "js" in static_dir:
                    js_files = [
                        f
                        for f in os.listdir(static_dir)
                        if f.endswith(".js") and "main" in f
                    ]
                    if js_files:
                        js_file = f"js/{js_files[0]}"
                elif "css" in static_dir:
                    css_files = [
                        f
                        for f in os.listdir(static_dir)
                        if f.endswith(".css") and "main" in f
                    ]
                    if css_files:
                        css_file = f"css/{css_files[0]}"
            except (OSError, IndexError):
                continue

    if js_file or css_file:
        return {
            "main_js": js_file or "js/main.js",
            "main_css": css_file or "css/main.css",
        }

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
        "main_js": "js/main.js",
        "main_css": "css/main.css",
    }


def home(request: HttpRequest) -> HttpResponse:
    assets = get_react_assets()
    logger.debug("Loading assets: %s", assets)
    return render(request, "index.html", {"assets": assets})


@require_GET
def robots_txt(request: HttpRequest) -> HttpResponse:
    """Serve the robots.txt file to prevent search engine indexing"""
    return HttpResponse("User-agent: *\nDisallow: /\n", content_type="text/plain")

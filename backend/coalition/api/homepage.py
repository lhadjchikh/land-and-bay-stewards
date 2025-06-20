from django.http import Http404, HttpRequest
from django.shortcuts import get_object_or_404
from ninja import Router

from coalition.core.models import ContentBlock, HomePage

from .schemas import ContentBlockOut, HomePageOut

router = Router()


@router.get("/", response=HomePageOut)
def get_homepage(request: HttpRequest) -> HomePage:
    """Get the active homepage configuration with all content blocks"""
    homepage = HomePage.get_active()
    if not homepage:
        raise Http404("No active homepage configuration found")

    return homepage


@router.get("/{homepage_id}/", response=HomePageOut)
def get_homepage_by_id(request: HttpRequest, homepage_id: int) -> HomePage:
    """Get a specific homepage configuration by ID"""
    return get_object_or_404(HomePage, id=homepage_id)


@router.get("/{homepage_id}/content-blocks/", response=list[ContentBlockOut])
def get_content_blocks(request: HttpRequest, homepage_id: int) -> list[ContentBlock]:
    """Get all content blocks for a specific homepage"""
    homepage = get_object_or_404(HomePage, id=homepage_id)
    return list(homepage.content_blocks.filter(is_visible=True).order_by("order"))


@router.get("/content-blocks/{block_id}/", response=ContentBlockOut)
def get_content_block(request: HttpRequest, block_id: int) -> ContentBlock:
    """Get a specific content block by ID"""
    return get_object_or_404(ContentBlock, id=block_id)

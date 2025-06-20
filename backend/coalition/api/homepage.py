from django.http import HttpRequest
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
        # Create a default homepage if none exists
        homepage = HomePage.objects.create(
            organization_name="Coalition Builder",
            tagline="Building strong advocacy partnerships",
            hero_title="Welcome to Coalition Builder",
            hero_subtitle="Empowering advocates to build strong policy coalitions",
            about_section_title="About Our Mission",
            about_section_content=(
                "We believe in the power of collective action to drive "
                "meaningful policy change. Our platform connects advocates, "
                "stakeholders, and organizations to build effective coalitions "
                "for important causes."
            ),
            contact_email="info@example.org",
            cta_title="Get Involved",
            cta_content=(
                "Join our coalition and help make a difference in policy " "advocacy."
            ),
            cta_button_text="Learn More",
            is_active=True,
        )

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

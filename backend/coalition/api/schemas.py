from datetime import datetime

from ninja import Schema


class PolicyCampaignOut(Schema):
    id: int
    title: str
    slug: str
    summary: str


class StakeholderOut(Schema):
    id: int
    name: str
    organization: str
    role: str
    email: str
    state: str
    county: str
    type: str
    created_at: datetime


class EndorsementOut(Schema):
    id: int
    stakeholder: StakeholderOut
    campaign: PolicyCampaignOut
    statement: str
    public_display: bool
    created_at: datetime


class LegislatorOut(Schema):
    id: int
    first_name: str
    last_name: str
    chamber: str
    state: str
    district: str | None = None
    is_senior: bool | None = None


class ContentBlockOut(Schema):
    id: int
    title: str
    block_type: str
    content: str
    image_url: str
    image_alt_text: str
    css_classes: str
    background_color: str
    order: int
    is_visible: bool
    created_at: datetime
    updated_at: datetime


class HomePageOut(Schema):
    id: int
    # Organization info
    organization_name: str
    tagline: str

    # Hero section
    hero_title: str
    hero_subtitle: str
    hero_background_image: str

    # Main content sections
    about_section_title: str
    about_section_content: str

    # Call to action
    cta_title: str
    cta_content: str
    cta_button_text: str
    cta_button_url: str

    # Contact information
    contact_email: str
    contact_phone: str

    # Social media
    facebook_url: str
    twitter_url: str
    instagram_url: str
    linkedin_url: str

    # Campaign section customization
    campaigns_section_title: str
    campaigns_section_subtitle: str
    show_campaigns_section: bool

    # Content blocks
    content_blocks: list[ContentBlockOut]

    # Meta information
    is_active: bool
    created_at: datetime
    updated_at: datetime

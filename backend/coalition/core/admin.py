from typing import TYPE_CHECKING

from django.contrib import admin
from django.core.exceptions import ValidationError
from django.forms import ModelForm

from .models import ContentBlock, HomePage

if TYPE_CHECKING:
    from django.db.models import QuerySet
    from django.http import HttpRequest


class ContentBlockInline(admin.TabularInline):
    """Inline admin for content blocks within HomePage admin"""

    model = ContentBlock
    extra = 0
    fields = ("title", "block_type", "content", "image_url", "order", "is_visible")
    ordering = ("order",)


class HomePageForm(ModelForm):
    """Custom form for HomePage admin with validation"""

    class Meta:
        model = HomePage
        fields = "__all__"

    def clean(self) -> dict:
        """Delegate validation to the model's clean method"""
        cleaned_data = super().clean()

        # Apply cleaned data to the instance for validation
        for field, value in cleaned_data.items():
            setattr(self.instance, field, value)

        # Call the model's clean method to centralize validation logic
        try:
            self.instance.clean()
        except ValidationError as e:
            # Convert model ValidationError to form ValidationError
            if hasattr(e, "message_dict") and e.message_dict:
                for field, messages in e.message_dict.items():
                    self.add_error(field, messages)
            else:
                # Non-field errors
                for message in e.messages:
                    self.add_error(None, message)

        return cleaned_data


@admin.register(HomePage)
class HomePageAdmin(admin.ModelAdmin):
    """Admin interface for HomePage model"""

    form = HomePageForm
    inlines = [ContentBlockInline]

    list_display = (
        "organization_name",
        "hero_title",
        "is_active",
        "updated_at",
        "created_at",
    )

    list_filter = ("is_active", "created_at", "updated_at")

    search_fields = ("organization_name", "hero_title", "tagline")

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        (
            "Organization Information",
            {
                "fields": (
                    "organization_name",
                    "tagline",
                    "contact_email",
                    "contact_phone",
                ),
            },
        ),
        (
            "Hero Section",
            {
                "fields": ("hero_title", "hero_subtitle", "hero_background_image"),
                "description": "Main banner section at the top of the homepage",
            },
        ),
        (
            "About Section",
            {
                "fields": ("about_section_title", "about_section_content"),
                "description": "Mission and organizational information section",
            },
        ),
        (
            "Call to Action",
            {
                "fields": (
                    "cta_title",
                    "cta_content",
                    "cta_button_text",
                    "cta_button_url",
                ),
                "description": "Primary call-to-action section",
            },
        ),
        (
            "Social Media",
            {
                "fields": (
                    "facebook_url",
                    "twitter_url",
                    "instagram_url",
                    "linkedin_url",
                ),
                "classes": ("collapse",),
                "description": "Social media profile links",
            },
        ),
        (
            "Campaigns Section",
            {
                "fields": (
                    "campaigns_section_title",
                    "campaigns_section_subtitle",
                    "show_campaigns_section",
                ),
                "description": "Configuration for the policy campaigns display section",
            },
        ),
        (
            "Settings",
            {
                "fields": ("is_active", "created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[HomePage]":
        """Order by most recently updated first"""
        return super().get_queryset(request).order_by("-updated_at")


@admin.register(ContentBlock)
class ContentBlockAdmin(admin.ModelAdmin):
    """Admin interface for ContentBlock model"""

    list_display = (
        "title",
        "block_type",
        "homepage",
        "order",
        "is_visible",
        "updated_at",
    )

    list_filter = ("block_type", "is_visible", "homepage", "created_at")

    search_fields = ("title", "content")

    list_editable = ("order", "is_visible")

    readonly_fields = ("created_at", "updated_at")

    fieldsets = (
        ("Content", {"fields": ("homepage", "title", "block_type", "content")}),
        (
            "Media",
            {
                "fields": ("image_url", "image_alt_text"),
                "classes": ("collapse",),
                "description": "Image settings for image-based content blocks",
            },
        ),
        (
            "Styling",
            {
                "fields": ("css_classes", "background_color"),
                "classes": ("collapse",),
                "description": "Optional styling customizations",
            },
        ),
        ("Display", {"fields": ("order", "is_visible", "created_at", "updated_at")}),
    )

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[ContentBlock]":
        """Order by homepage and then by order"""
        return super().get_queryset(request).order_by("homepage", "order")

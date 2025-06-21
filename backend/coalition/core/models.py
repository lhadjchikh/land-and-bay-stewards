from typing import TYPE_CHECKING

from django.core.exceptions import ValidationError
from django.db import models

if TYPE_CHECKING:
    from typing import Any


class HomePage(models.Model):
    """
    Model for managing homepage content.
    Only one instance should exist - the active homepage configuration.
    """

    # Basic organization info
    organization_name = models.CharField(
        max_length=200,
        help_text="Name of the organization",
    )
    tagline = models.CharField(
        max_length=500,
        help_text="Brief tagline or slogan for the organization",
    )

    # Hero section
    hero_title = models.CharField(
        max_length=300,
        help_text="Main headline displayed prominently on the homepage",
    )
    hero_subtitle = models.TextField(
        blank=True,
        help_text="Optional subtitle or description under the hero title",
    )
    hero_background_image = models.URLField(
        blank=True,
        help_text="URL to hero background image (optional)",
    )

    # Main content sections
    about_section_title = models.CharField(
        max_length=200,
        default="About Our Mission",
        help_text="Title for the about/mission section",
    )
    about_section_content = models.TextField(
        help_text="Main content describing the organization's mission and goals",
    )

    # Call to action
    cta_title = models.CharField(
        max_length=200,
        default="Get Involved",
        help_text="Title for the call-to-action section",
    )
    cta_content = models.TextField(
        blank=True,
        help_text="Description for how people can get involved",
    )
    cta_button_text = models.CharField(
        max_length=100,
        default="Learn More",
        help_text="Text for the call-to-action button",
    )
    cta_button_url = models.URLField(
        blank=True,
        help_text="URL for the call-to-action button",
    )

    # Contact information
    contact_email = models.EmailField(help_text="Primary contact email address")
    contact_phone = models.CharField(
        max_length=20,
        blank=True,
        help_text="Contact phone number (optional)",
    )

    # Social media
    facebook_url = models.URLField(blank=True, help_text="Facebook page URL")
    twitter_url = models.URLField(blank=True, help_text="Twitter/X profile URL")
    instagram_url = models.URLField(blank=True, help_text="Instagram profile URL")
    linkedin_url = models.URLField(blank=True, help_text="LinkedIn page URL")

    # Campaign section customization
    campaigns_section_title = models.CharField(
        max_length=200,
        default="Policy Campaigns",
        help_text="Title for the campaigns section",
    )
    campaigns_section_subtitle = models.TextField(
        blank=True,
        help_text="Optional subtitle for the campaigns section",
    )
    show_campaigns_section = models.BooleanField(
        default=True,
        help_text="Whether to display the campaigns section on the homepage",
    )

    # Meta information
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this homepage configuration is active",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Homepage Configuration"
        verbose_name_plural = "Homepage Configurations"

    def __str__(self) -> str:
        return f"Homepage: {self.organization_name}"

    def clean(self) -> None:
        """Ensure only one active homepage configuration exists"""
        if self.is_active:
            # Check if there's already an active homepage that's not this one
            existing_active = HomePage.objects.filter(is_active=True).exclude(
                pk=self.pk,
            )
            if existing_active.exists():
                raise ValidationError(
                    "Only one homepage configuration can be active at a time. "
                    "Please deactivate the current active configuration first.",
                )

    def save(self, *args: "Any", **kwargs: "Any") -> None:
        self.full_clean()
        super().save(*args, **kwargs)

    @classmethod
    def get_active(cls) -> "HomePage | None":
        """Get the currently active homepage configuration"""
        try:
            return cls.objects.get(is_active=True)
        except cls.DoesNotExist:
            return None
        except cls.MultipleObjectsReturned:
            # If somehow multiple active exist, return the most recent
            return cls.objects.filter(is_active=True).order_by("-updated_at").first()


class ContentBlock(models.Model):
    """
    Flexible content blocks that can be added to the homepage.
    Allows for more dynamic content sections beyond the fixed structure.
    """

    BLOCK_TYPES = [
        ("text", "Text Block"),
        ("image", "Image Block"),
        ("text_image", "Text + Image Block"),
        ("quote", "Quote Block"),
        ("stats", "Statistics Block"),
        ("custom_html", "Custom HTML Block"),
    ]

    homepage = models.ForeignKey(
        HomePage,
        on_delete=models.CASCADE,
        related_name="content_blocks",
    )

    title = models.CharField(
        max_length=200,
        blank=True,
        help_text="Optional title for this content block",
    )

    block_type = models.CharField(
        max_length=20,
        choices=BLOCK_TYPES,
        default="text",
        help_text="Type of content block",
    )

    content = models.TextField(
        help_text="Main content for this block (text, HTML, etc.)",
    )

    image_url = models.URLField(
        blank=True,
        help_text="Image URL for image or text+image blocks",
    )

    image_alt_text = models.CharField(
        max_length=200,
        blank=True,
        help_text="Alt text for the image (accessibility)",
    )

    # Layout options
    css_classes = models.CharField(
        max_length=200,
        blank=True,
        help_text="Additional CSS classes for styling (optional)",
    )

    background_color = models.CharField(
        max_length=7,
        blank=True,
        help_text="Background color in hex format (e.g., #ffffff)",
    )

    # Ordering and visibility
    order = models.PositiveIntegerField(
        default=0,
        help_text="Order in which this block appears (lower numbers first)",
    )

    is_visible = models.BooleanField(
        default=True,
        help_text="Whether this block is visible on the homepage",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "created_at"]
        verbose_name = "Content Block"
        verbose_name_plural = "Content Blocks"

    def __str__(self) -> str:
        return f"Block: {self.title or self.block_type} (Order: {self.order})"

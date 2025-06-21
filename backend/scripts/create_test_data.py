#!/usr/bin/env python
"""
Script to create test data for integration tests.
Run this script with Django's environment loaded.
"""

import os
import sys

import django

# Initialize Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "coalition.core.settings")
django.setup()


def create_test_data() -> int:
    """Create test data for integration tests if it doesn't already exist."""
    try:
        # Import models after Django is initialized
        from coalition.campaigns.models import PolicyCampaign
        from coalition.core.models import ContentBlock, HomePage
        from coalition.endorsements.models import Endorsement
        from coalition.legislators.models import Legislator
        from coalition.stakeholders.models import Stakeholder

        # Create a test campaign if none exists
        if not PolicyCampaign.objects.exists():
            PolicyCampaign.objects.create(
                title="Test Campaign",
                slug="test-campaign",
                summary="This is a test campaign for integration testing",
            )
            print("Created test campaign")

        # Create a test stakeholder if none exists
        if not Stakeholder.objects.exists():
            stakeholder = Stakeholder.objects.create(
                name="Test Stakeholder",
                organization="Test Organization",
                role="Test Role",
                email="test@example.com",
                state="MD",
                county="Test County",
                type="other",
            )
            print("Created test stakeholder")

            # Create a test endorsement if none exists
            campaign = PolicyCampaign.objects.first()
            if campaign and not Endorsement.objects.exists():
                Endorsement.objects.create(
                    stakeholder=stakeholder,
                    campaign=campaign,
                    statement="Test endorsement statement",
                    public_display=True,
                )
                print("Created test endorsement")

        # Create a test legislator if none exists
        if not Legislator.objects.exists():
            Legislator.objects.create(
                bioguide_id="TEST001",
                first_name="Test",
                last_name="Legislator",
                chamber="House",
                state="MD",
                district="01",
                party="D",
            )
            print("Created test legislator")

        # Create a test homepage if none exists
        if not HomePage.objects.exists():
            homepage = HomePage.objects.create(
                organization_name="Test Coalition",
                tagline="Building test partnerships",
                hero_title="Welcome to Test Coalition",
                hero_subtitle="Testing our coalition-building platform",
                about_section_title="About Our Test Mission",
                about_section_content=(
                    "We are dedicated to testing and improving our coalition-building "
                    "platform to help organizations create meaningful policy change."
                ),
                cta_title="Join Our Test",
                cta_content="Help us test and improve this platform",
                cta_button_text="Get Started",
                cta_button_url="/campaigns/",
                contact_email="test@coalition.org",
                contact_phone="(555) 123-4567",
                campaigns_section_title="Test Campaigns",
                campaigns_section_subtitle="Our current testing initiatives",
                show_campaigns_section=True,
                is_active=True,
            )
            print("Created test homepage")

            # Create test content blocks
            ContentBlock.objects.create(
                homepage=homepage,
                title="Why Testing Matters",
                block_type="text",
                content=(
                    "<p>Thorough testing ensures our platform works reliably for all "
                    "coalition-building needs. We test every feature to make sure "
                    "advocates can focus on their mission, not technical issues.</p>"
                ),
                order=1,
                is_visible=True,
            )

            ContentBlock.objects.create(
                homepage=homepage,
                title="Our Test Impact",
                block_type="stats",
                content=(
                    '<div class="grid grid-cols-3 gap-4 text-center">'
                    '<div><div class="text-3xl font-bold text-blue-600">100+</div>'
                    '<div class="text-gray-600">Test Cases</div></div>'
                    '<div><div class="text-3xl font-bold text-blue-600">50+</div>'
                    '<div class="text-gray-600">Features Tested</div></div>'
                    '<div><div class="text-3xl font-bold text-blue-600">99%</div>'
                    '<div class="text-gray-600">Uptime</div></div>'
                    '</div>'
                ),
                order=2,
                is_visible=True,
            )
            print("Created test content blocks")

        return 0  # Success
    except ImportError as e:
        print(f"Error importing models: {e}")
        return 1  # Error


if __name__ == "__main__":
    # When run as a script, execute the function and exit with its return code
    sys.exit(create_test_data())

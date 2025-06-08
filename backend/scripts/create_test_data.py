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
        from coalitionbuilder.campaigns.models import PolicyCampaign
        from coalitionbuilder.endorsements.models import Endorsement
        from coalitionbuilder.legislators.models import Legislator
        from coalitionbuilder.stakeholders.models import Stakeholder

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

        return 0  # Success
    except ImportError as e:
        print(f"Error importing models: {e}")
        return 1  # Error


if __name__ == "__main__":
    # When run as a script, execute the function and exit with its return code
    sys.exit(create_test_data())

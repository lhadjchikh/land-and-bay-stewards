#!/usr/bin/env python
"""
Script to create test data for integration tests.
Run this script with Django's environment loaded.
"""

import os
import sys

import django

# Initialize Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "landandbay.core.settings")
django.setup()


def create_test_data() -> int:
    """Create test data for integration tests if it doesn't already exist."""
    try:
        # Import models after Django is initialized
        from landandbay.campaigns.models import PolicyCampaign
        from landandbay.endorsers.models import Endorser
        from landandbay.legislators.models import Legislator

        # Create a test campaign if none exists
        if not PolicyCampaign.objects.exists():
            PolicyCampaign.objects.create(
                title="Test Campaign",
                slug="test-campaign",
                summary="This is a test campaign for integration testing",
            )
            print("Created test campaign")

        # Create a test endorser if none exists
        if not Endorser.objects.exists():
            Endorser.objects.create(
                name="Test Endorser",
                organization="Test Organization",
                role="Test Role",
                email="test@example.com",
                state="MD",
                county="Test County",
                type="other",
                campaign=PolicyCampaign.objects.first(),
            )
            print("Created test endorser")

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

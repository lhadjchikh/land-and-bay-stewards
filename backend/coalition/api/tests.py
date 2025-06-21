from django.test import TestCase
from django.test.client import Client

from coalition.core.models import ContentBlock, HomePage


class HomepageAPITest(TestCase):
    def setUp(self) -> None:
        # Use Django's test client
        self.client = Client()

        # Create test homepage
        self.homepage = HomePage.objects.create(
            organization_name="Test Organization",
            tagline="Building test coalitions",
            hero_title="Welcome to Test Organization",
            hero_subtitle="Making a difference in testing",
            hero_background_image="https://example.com/hero.jpg",
            about_section_title="About Our Test Mission",
            about_section_content=(
                "We are dedicated to thorough testing of our platform."
            ),
            cta_title="Join Our Test",
            cta_content="Help us test this platform",
            cta_button_text="Get Started",
            cta_button_url="https://example.com/join",
            contact_email="test@organization.org",
            contact_phone="(555) 123-4567",
            facebook_url="https://facebook.com/testorg",
            twitter_url="https://twitter.com/testorg",
            instagram_url="https://instagram.com/testorg",
            linkedin_url="https://linkedin.com/company/testorg",
            campaigns_section_title="Test Campaigns",
            campaigns_section_subtitle="Our current testing initiatives",
            show_campaigns_section=True,
            is_active=True,
        )

        # Create test content blocks
        self.content_block1 = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Test Block 1",
            block_type="text",
            content="This is the first test content block.",
            order=1,
            is_visible=True,
        )

        self.content_block2 = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Test Block 2",
            block_type="image",
            content="This is the second test content block.",
            image_url="https://example.com/image.jpg",
            image_alt_text="Test image",
            order=2,
            is_visible=True,
        )

        # Create hidden content block
        self.hidden_block = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Hidden Block",
            block_type="text",
            content="This block should not appear in API response.",
            order=3,
            is_visible=False,
        )

    def test_get_homepage_success(self) -> None:
        """Test successful homepage retrieval"""
        response = self.client.get("/api/homepage/")

        assert response.status_code == 200
        data = response.json()

        # Check basic homepage data
        assert data["organization_name"] == "Test Organization"
        assert data["tagline"] == "Building test coalitions"
        assert data["hero_title"] == "Welcome to Test Organization"
        assert data["hero_subtitle"] == "Making a difference in testing"
        assert data["hero_background_image"] == "https://example.com/hero.jpg"
        assert data["about_section_title"] == "About Our Test Mission"
        assert (
            data["about_section_content"]
            == "We are dedicated to thorough testing of our platform."
        )
        assert data["contact_email"] == "test@organization.org"
        assert data["contact_phone"] == "(555) 123-4567"
        assert data["is_active"]

        # Check social media URLs
        assert data["facebook_url"] == "https://facebook.com/testorg"
        assert data["twitter_url"] == "https://twitter.com/testorg"
        assert data["instagram_url"] == "https://instagram.com/testorg"
        assert data["linkedin_url"] == "https://linkedin.com/company/testorg"

        # Check CTA data
        assert data["cta_title"] == "Join Our Test"
        assert data["cta_content"] == "Help us test this platform"
        assert data["cta_button_text"] == "Get Started"
        assert data["cta_button_url"] == "https://example.com/join"

        # Check campaigns section
        assert data["campaigns_section_title"] == "Test Campaigns"
        assert data["campaigns_section_subtitle"] == "Our current testing initiatives"
        assert data["show_campaigns_section"]

        # Check content blocks
        assert "content_blocks" in data
        content_blocks = data["content_blocks"]
        assert len(content_blocks) == 2  # Only visible blocks

        # Check first content block
        block1 = content_blocks[0]
        assert block1["title"] == "Test Block 1"
        assert block1["block_type"] == "text"
        assert block1["content"] == "This is the first test content block."
        assert block1["order"] == 1
        assert block1["is_visible"]

        # Check second content block
        block2 = content_blocks[1]
        assert block2["title"] == "Test Block 2"
        assert block2["block_type"] == "image"
        assert block2["content"] == "This is the second test content block."
        assert block2["image_url"] == "https://example.com/image.jpg"
        assert block2["image_alt_text"] == "Test image"
        assert block2["order"] == 2
        assert block2["is_visible"]

        # Verify hidden block is not included
        block_titles = [block["title"] for block in content_blocks]
        assert "Hidden Block" not in block_titles

    def test_get_homepage_no_active_homepage(self) -> None:
        """Test homepage retrieval when no active homepage exists"""
        # Deactivate the homepage
        self.homepage.is_active = False
        self.homepage.save()

        response = self.client.get("/api/homepage/")
        assert response.status_code == 404

        data = response.json()
        assert "detail" in data
        assert data["detail"] == "Not Found"

    def test_get_homepage_no_homepage_exists(self) -> None:
        """Test homepage retrieval when no homepage exists at all"""
        # Delete the homepage
        self.homepage.delete()

        response = self.client.get("/api/homepage/")
        assert response.status_code == 404

        data = response.json()
        assert "detail" in data
        assert data["detail"] == "Not Found"

    def test_get_homepage_multiple_active_returns_most_recent(self) -> None:
        """Test that when multiple active homepages exist, most recent is returned"""
        # Create another active homepage (bypassing validation by using bulk_create)
        HomePage.objects.bulk_create(
            [
                HomePage(
                    organization_name="Second Organization",
                    tagline="Second tagline",
                    hero_title="Second Hero Title",
                    about_section_content="Second about content",
                    contact_email="second@organization.org",
                    is_active=True,
                ),
            ],
        )

        response = self.client.get("/api/homepage/")
        assert response.status_code == 200

        data = response.json()
        # Should return the more recent homepage (the second one)
        assert data["organization_name"] == "Second Organization"
        assert data["tagline"] == "Second tagline"

    def test_content_blocks_ordering(self) -> None:
        """Test that content blocks are returned in correct order"""
        # Create additional blocks with different orders
        ContentBlock.objects.create(
            homepage=self.homepage,
            title="Block Order 0",
            content="First block",
            order=0,
            is_visible=True,
        )

        ContentBlock.objects.create(
            homepage=self.homepage,
            title="Block Order 5",
            content="Last block",
            order=5,
            is_visible=True,
        )

        response = self.client.get("/api/homepage/")
        assert response.status_code == 200

        data = response.json()
        content_blocks = data["content_blocks"]

        # Should be ordered by order field
        expected_order = [0, 1, 2, 5]
        actual_order = [block["order"] for block in content_blocks]
        assert actual_order == expected_order

    def test_content_blocks_with_empty_fields(self) -> None:
        """Test content blocks with empty optional fields"""
        # Create block with minimal data
        ContentBlock.objects.create(
            homepage=self.homepage,
            content="Minimal block content",
            order=10,
            is_visible=True,
        )

        response = self.client.get("/api/homepage/")
        assert response.status_code == 200

        data = response.json()
        content_blocks = data["content_blocks"]

        # Find the minimal block
        minimal_block = None
        for block in content_blocks:
            if block["order"] == 10:
                minimal_block = block
                break

        assert minimal_block is not None
        assert minimal_block["title"] == ""
        assert minimal_block["block_type"] == "text"  # default value
        assert minimal_block["image_url"] == ""
        assert minimal_block["image_alt_text"] == ""
        assert minimal_block["css_classes"] == ""
        assert minimal_block["background_color"] == ""

    def test_homepage_api_response_structure(self) -> None:
        """Test that the API response includes all expected fields"""
        response = self.client.get("/api/homepage/")
        assert response.status_code == 200

        data = response.json()

        # Check that all expected fields are present
        required_fields = [
            "id",
            "organization_name",
            "tagline",
            "hero_title",
            "hero_subtitle",
            "hero_background_image",
            "about_section_title",
            "about_section_content",
            "cta_title",
            "cta_content",
            "cta_button_text",
            "cta_button_url",
            "contact_email",
            "contact_phone",
            "facebook_url",
            "twitter_url",
            "instagram_url",
            "linkedin_url",
            "campaigns_section_title",
            "campaigns_section_subtitle",
            "show_campaigns_section",
            "content_blocks",
            "is_active",
            "created_at",
            "updated_at",
        ]

        for field in required_fields:
            assert field in data, f"Missing field: {field}"

        # Check content block structure
        if data["content_blocks"]:
            content_block = data["content_blocks"][0]
            content_block_fields = [
                "id",
                "title",
                "block_type",
                "content",
                "image_url",
                "image_alt_text",
                "css_classes",
                "background_color",
                "order",
                "is_visible",
                "created_at",
                "updated_at",
            ]

            for field in content_block_fields:
                assert field in content_block, f"Missing content block field: {field}"

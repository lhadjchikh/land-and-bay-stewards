from django.core.exceptions import ValidationError
from django.test import TestCase

from .models import ContentBlock, HomePage


class HomePageModelTest(TestCase):
    def setUp(self) -> None:
        self.homepage_data = {
            "organization_name": "Test Organization",
            "tagline": "Test tagline for organization",
            "hero_title": "Welcome to Test Organization",
            "hero_subtitle": "Making a difference in our community",
            "about_section_title": "About Our Mission",
            "about_section_content": "We are dedicated to creating positive change.",
            "contact_email": "contact@testorg.org",
            "cta_title": "Join Us",
            "cta_content": "Get involved with our mission",
            "cta_button_text": "Learn More",
        }

    def test_create_homepage(self) -> None:
        """Test creating a homepage with valid data"""
        homepage = HomePage.objects.create(**self.homepage_data)
        assert homepage.organization_name == "Test Organization"
        assert homepage.tagline == "Test tagline for organization"
        assert homepage.hero_title == "Welcome to Test Organization"
        assert homepage.contact_email == "contact@testorg.org"
        assert homepage.is_active
        assert homepage.created_at is not None
        assert homepage.updated_at is not None

    def test_homepage_str_representation(self) -> None:
        """Test string representation of homepage"""
        homepage = HomePage.objects.create(**self.homepage_data)
        expected_str = "Homepage: Test Organization"
        assert str(homepage) == expected_str

    def test_default_values(self) -> None:
        """Test that default values are set correctly"""
        minimal_data = {
            "organization_name": "Minimal Org",
            "tagline": "Minimal tagline",
            "hero_title": "Minimal Hero",
            "about_section_content": "Minimal content",
            "contact_email": "minimal@test.org",
        }
        homepage = HomePage.objects.create(**minimal_data)
        
        assert homepage.about_section_title == "About Our Mission"
        assert homepage.cta_title == "Get Involved"
        assert homepage.cta_button_text == "Learn More"
        assert homepage.campaigns_section_title == "Policy Campaigns"
        assert homepage.show_campaigns_section
        assert homepage.is_active

    def test_single_active_homepage_constraint(self) -> None:
        """Test that only one homepage can be active at a time"""
        # Create first active homepage
        homepage1 = HomePage.objects.create(**self.homepage_data)
        assert homepage1.is_active

        # Create second homepage - should also be active initially
        data2 = self.homepage_data.copy()
        data2["organization_name"] = "Second Organization"
        data2["contact_email"] = "contact2@testorg.org"
        
        # This should raise a ValidationError due to clean() method
        with self.assertRaises(ValidationError):
            homepage2 = HomePage(**data2)
            homepage2.save()

    def test_get_active_classmethod(self) -> None:
        """Test the get_active classmethod"""
        # No active homepage initially
        assert HomePage.get_active() is None

        # Create an active homepage
        homepage = HomePage.objects.create(**self.homepage_data)
        active_homepage = HomePage.get_active()
        assert active_homepage == homepage

    def test_get_active_multiple_active_returns_most_recent(self) -> None:
        """Test that get_active returns most recent when multiple exist"""
        # Create first homepage
        homepage1 = HomePage.objects.create(**self.homepage_data)
        
        # Create second homepage bypassing validation using bulk_create
        data2 = self.homepage_data.copy()
        data2["organization_name"] = "Second Organization"
        data2["contact_email"] = "contact2@testorg.org"
        
        HomePage.objects.bulk_create([HomePage(**data2)])
        homepage2 = HomePage.objects.filter(organization_name="Second Organization").first()

        # Both should be active, get_active should return the most recent
        active_homepage = HomePage.get_active()
        assert active_homepage == homepage2

    def test_email_validation(self) -> None:
        """Test email field validation"""
        invalid_data = self.homepage_data.copy()
        invalid_data["contact_email"] = "invalid-email"

        homepage = HomePage(**invalid_data)
        with self.assertRaises(ValidationError):
            homepage.full_clean()

    def test_optional_fields(self) -> None:
        """Test that optional fields can be blank"""
        minimal_data = {
            "organization_name": "Minimal Org",
            "tagline": "Minimal tagline",
            "hero_title": "Minimal Hero",
            "about_section_content": "Minimal content",
            "contact_email": "minimal@test.org",
        }
        homepage = HomePage.objects.create(**minimal_data)
        
        # These should be blank/empty
        assert homepage.hero_subtitle == ""
        assert homepage.hero_background_image == ""
        assert homepage.contact_phone == ""
        assert homepage.facebook_url == ""
        assert homepage.twitter_url == ""
        assert homepage.instagram_url == ""
        assert homepage.linkedin_url == ""
        assert homepage.cta_content == ""
        assert homepage.cta_button_url == ""
        assert homepage.campaigns_section_subtitle == ""


class ContentBlockModelTest(TestCase):
    def setUp(self) -> None:
        self.homepage = HomePage.objects.create(
            organization_name="Test Organization",
            tagline="Test tagline",
            hero_title="Welcome",
            about_section_content="About content",
            contact_email="contact@test.org",
        )
        
        self.content_block_data = {
            "homepage": self.homepage,
            "title": "Test Content Block",
            "block_type": "text",
            "content": "This is test content for the block",
            "order": 1,
        }

    def test_create_content_block(self) -> None:
        """Test creating a content block with valid data"""
        block = ContentBlock.objects.create(**self.content_block_data)
        assert block.title == "Test Content Block"
        assert block.block_type == "text"
        assert block.content == "This is test content for the block"
        assert block.homepage == self.homepage
        assert block.order == 1
        assert block.is_visible
        assert block.created_at is not None
        assert block.updated_at is not None

    def test_content_block_str_representation(self) -> None:
        """Test string representation of content block"""
        block = ContentBlock.objects.create(**self.content_block_data)
        expected_str = "Block: Test Content Block (Order: 1)"
        assert str(block) == expected_str

    def test_content_block_str_without_title(self) -> None:
        """Test string representation when title is blank"""
        data = self.content_block_data.copy()
        data["title"] = ""
        block = ContentBlock.objects.create(**data)
        expected_str = "Block: text (Order: 1)"
        assert str(block) == expected_str

    def test_content_block_types(self) -> None:
        """Test all valid content block types"""
        valid_types = ["text", "image", "text_image", "quote", "stats", "custom_html"]
        
        for i, block_type in enumerate(valid_types):
            data = self.content_block_data.copy()
            data["block_type"] = block_type
            data["title"] = f"Test {block_type} Block"
            data["order"] = i + 1
            block = ContentBlock.objects.create(**data)
            assert block.block_type == block_type

    def test_default_values(self) -> None:
        """Test that default values are set correctly"""
        minimal_data = {
            "homepage": self.homepage,
            "content": "Minimal content",
        }
        block = ContentBlock.objects.create(**minimal_data)
        
        assert block.title == ""
        assert block.block_type == "text"
        assert block.order == 0
        assert block.is_visible
        assert block.image_url == ""
        assert block.image_alt_text == ""
        assert block.css_classes == ""
        assert block.background_color == ""

    def test_content_block_ordering(self) -> None:
        """Test that content blocks are ordered correctly"""
        # Create blocks with different orders
        block1 = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Block 1",
            content="Content 1",
            order=3,
        )
        block2 = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Block 2",
            content="Content 2",
            order=1,
        )
        block3 = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Block 3",
            content="Content 3",
            order=2,
        )

        # Query all blocks - should be ordered by order field
        blocks = list(ContentBlock.objects.all())
        assert blocks[0] == block2  # order=1
        assert blocks[1] == block3  # order=2
        assert blocks[2] == block1  # order=3

    def test_content_block_homepage_relationship(self) -> None:
        """Test the relationship between homepage and content blocks"""
        block1 = ContentBlock.objects.create(**self.content_block_data)
        
        data2 = self.content_block_data.copy()
        data2["title"] = "Second Block"
        data2["order"] = 2
        block2 = ContentBlock.objects.create(**data2)

        # Test reverse relationship
        homepage_blocks = self.homepage.content_blocks.all()
        assert homepage_blocks.count() == 2
        assert block1 in homepage_blocks
        assert block2 in homepage_blocks

    def test_content_block_cascade_delete(self) -> None:
        """Test that content blocks are deleted when homepage is deleted"""
        block = ContentBlock.objects.create(**self.content_block_data)
        block_id = block.id
        
        # Delete homepage
        self.homepage.delete()
        
        # Content block should also be deleted
        assert not ContentBlock.objects.filter(id=block_id).exists()

    def test_visibility_filter(self) -> None:
        """Test filtering content blocks by visibility"""
        # Create visible block
        visible_block = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Visible Block",
            content="Visible content",
            is_visible=True,
        )
        
        # Create hidden block
        hidden_block = ContentBlock.objects.create(
            homepage=self.homepage,
            title="Hidden Block",
            content="Hidden content",
            is_visible=False,
        )

        # Filter for visible blocks only
        visible_blocks = ContentBlock.objects.filter(is_visible=True)
        assert visible_blocks.count() == 1
        assert visible_block in visible_blocks
        assert hidden_block not in visible_blocks

        # Filter for all blocks
        all_blocks = ContentBlock.objects.all()
        assert all_blocks.count() == 2
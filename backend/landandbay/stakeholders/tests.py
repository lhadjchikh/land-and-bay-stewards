from django.core.exceptions import ValidationError
from django.test import TestCase

from .models import Stakeholder


class StakeholderModelTest(TestCase):
    def setUp(self) -> None:
        self.stakeholder_data = {
            "name": "John Doe",
            "organization": "Test Farm LLC",
            "role": "Owner",
            "email": "john@testfarm.com",
            "state": "MD",
            "county": "Anne Arundel",
            "type": "farmer",
        }

    def test_create_stakeholder(self) -> None:
        """Test creating a stakeholder with valid data"""
        stakeholder = Stakeholder.objects.create(**self.stakeholder_data)
        assert stakeholder.name == "John Doe"
        assert stakeholder.organization == "Test Farm LLC"
        assert stakeholder.type == "farmer"
        assert stakeholder.state == "MD"
        assert stakeholder.created_at is not None

    def test_stakeholder_str_representation(self) -> None:
        """Test string representation of stakeholder"""
        stakeholder = Stakeholder.objects.create(**self.stakeholder_data)
        expected_str = "Test Farm LLC – John Doe"
        assert str(stakeholder) == expected_str

    def test_stakeholder_type_choices(self) -> None:
        """Test that only valid stakeholder types are accepted"""
        valid_types = ["farmer", "waterman", "business", "nonprofit", "other"]

        for stakeholder_type in valid_types:
            data = self.stakeholder_data.copy()
            data["type"] = stakeholder_type
            data["email"] = f"test{stakeholder_type}@example.com"  # Make emails unique
            data["organization"] = f"Test {stakeholder_type} Org"  # Make orgs unique
            stakeholder = Stakeholder.objects.create(**data)
            assert stakeholder.type == stakeholder_type

    def test_optional_fields(self) -> None:
        """Test that optional fields can be blank"""
        minimal_data = {
            "name": "Jane Smith",
            "organization": "Smith Industries",
            "email": "jane@smith.com",
            "state": "VA",
            "type": "business",
        }
        stakeholder = Stakeholder.objects.create(**minimal_data)
        assert stakeholder.role == ""
        assert stakeholder.county == ""

    def test_email_validation(self) -> None:
        """Test email field validation"""
        invalid_data = self.stakeholder_data.copy()
        invalid_data["email"] = "invalid-email"

        stakeholder = Stakeholder(**invalid_data)
        with self.assertRaises(ValidationError):
            stakeholder.full_clean()

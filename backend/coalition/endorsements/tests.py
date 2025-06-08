from django.db import IntegrityError
from django.test import TestCase

from coalition.campaigns.models import PolicyCampaign
from coalition.stakeholders.models import Stakeholder

from .models import Endorsement


class EndorsementModelTest(TestCase):
    def setUp(self) -> None:
        # Create a stakeholder
        self.stakeholder = Stakeholder.objects.create(
            name="Test Farmer",
            organization="Test Farm",
            email="test@farm.com",
            state="MD",
            type="farmer",
        )

        # Create a campaign
        self.campaign = PolicyCampaign.objects.create(
            title="Clean Water Act",
            slug="clean-water-act",
            summary="Protecting our waterways",
        )

    def test_create_endorsement(self) -> None:
        """Test creating an endorsement"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
            statement="We strongly support this initiative",
            public_display=True,
        )

        assert endorsement.stakeholder == self.stakeholder
        assert endorsement.campaign == self.campaign
        assert endorsement.statement == "We strongly support this initiative"
        assert endorsement.public_display
        assert endorsement.created_at is not None

    def test_endorsement_str_representation(self) -> None:
        """Test string representation of endorsement"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )
        expected_str = f"{self.stakeholder} endorses {self.campaign}"
        assert str(endorsement) == expected_str

    def test_unique_stakeholder_campaign_constraint(self) -> None:
        """Test that a stakeholder cannot endorse the same campaign twice"""
        # Create first endorsement
        Endorsement.objects.create(stakeholder=self.stakeholder, campaign=self.campaign)

        # Try to create duplicate endorsement
        with self.assertRaises(IntegrityError):
            Endorsement.objects.create(
                stakeholder=self.stakeholder,
                campaign=self.campaign,
            )

    def test_optional_statement(self) -> None:
        """Test that statement field is optional"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )
        assert endorsement.statement == ""

    def test_default_public_display(self) -> None:
        """Test that public_display defaults to True"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )
        assert endorsement.public_display

    def test_cascade_delete_stakeholder(self) -> None:
        """Test that deleting stakeholder deletes endorsements"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )

        stakeholder_id = self.stakeholder.id
        endorsement_id = endorsement.id

        self.stakeholder.delete()

        # Stakeholder should be deleted
        assert not Stakeholder.objects.filter(id=stakeholder_id).exists()
        # Endorsement should also be deleted
        assert not Endorsement.objects.filter(id=endorsement_id).exists()

    def test_cascade_delete_campaign(self) -> None:
        """Test that deleting campaign deletes endorsements"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )

        campaign_id = self.campaign.id
        endorsement_id = endorsement.id

        self.campaign.delete()

        # Campaign should be deleted
        assert not PolicyCampaign.objects.filter(id=campaign_id).exists()
        # Endorsement should also be deleted
        assert not Endorsement.objects.filter(id=endorsement_id).exists()
        # Stakeholder should remain
        assert Stakeholder.objects.filter(id=self.stakeholder.id).exists()

    def test_related_name_stakeholder_endorsements(self) -> None:
        """Test that stakeholder.endorsements related manager works"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )

        endorsements = self.stakeholder.endorsements.all()
        assert endorsements.count() == 1
        assert endorsements.first() == endorsement

    def test_related_name_campaign_endorsements(self) -> None:
        """Test that campaign.endorsements related manager works"""
        endorsement = Endorsement.objects.create(
            stakeholder=self.stakeholder,
            campaign=self.campaign,
        )

        endorsements = self.campaign.endorsements.all()
        assert endorsements.count() == 1
        assert endorsements.first() == endorsement

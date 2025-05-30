from django.test import Client, TestCase

from campaigns.models import PolicyCampaign
from endorsers.models import Endorser
from legislators.models import Legislator


class ApiDocsTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()

    def test_api_docs_endpoint_returns_200(self) -> None:
        """Test that the API docs endpoint returns a 200 status code"""
        response = self.client.get("/api/docs")
        assert response.status_code == 200

    def test_api_docs_contains_version(self) -> None:
        """Test that the API docs page contains the correct API version"""
        response = self.client.get("/api/docs")
        # For Python 3.13, check the OpenAPI schema directly
        response_schema = self.client.get("/api/openapi.json")
        schema_data = response_schema.json()
        self.assertEqual(schema_data.get("info", {}).get("version"), "1.0")

    def test_api_routers_exist(self) -> None:
        """Test that the API docs page contains all registered routers"""
        response = self.client.get("/api/docs")
        # For Python 3.13, check the OpenAPI schema directly
        response_schema = self.client.get("/api/openapi.json")
        schema_data = response_schema.json()
        paths = schema_data.get("paths", {}).keys()
        self.assertIn("/api/campaigns/", paths)
        self.assertIn("/api/endorsers/", paths)
        self.assertIn("/api/legislators/", paths)


class CampaignsApiTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.campaign = PolicyCampaign.objects.create(
            title="Test Campaign",
            slug="test-campaign",
            summary="This is a test campaign",
        )

    def test_list_campaigns_endpoint_returns_200(self) -> None:
        """Test that the campaigns list endpoint returns a 200 status code"""
        response = self.client.get("/api/campaigns/")
        assert response.status_code == 200

    def test_list_campaigns_returns_correct_data(self) -> None:
        """Test that the campaigns list endpoint returns the correct data"""
        response = self.client.get("/api/campaigns/")
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Test Campaign"
        assert data[0]["slug"] == "test-campaign"
        assert data[0]["summary"] == "This is a test campaign"


class EndorsersApiTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.campaign = PolicyCampaign.objects.create(
            title="Test Campaign",
            slug="test-campaign",
            summary="This is a test campaign",
        )
        self.endorser = Endorser.objects.create(
            name="Test Endorser",
            organization="Test Organization",
            email="test@example.com",
            state="MD",
            type="farmer",
            campaign=self.campaign,
        )

    def test_list_endorsers_endpoint_returns_200(self) -> None:
        """Test that the endorsers list endpoint returns a 200 status code"""
        response = self.client.get("/api/endorsers/")
        assert response.status_code == 200

    def test_list_endorsers_returns_correct_data(self) -> None:
        """Test that the endorsers list endpoint returns the correct data"""
        response = self.client.get("/api/endorsers/")
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Test Endorser"
        assert data[0]["organization"] == "Test Organization"
        assert data[0]["state"] == "MD"
        assert data[0]["type"] == "farmer"


class LegislatorsApiTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.legislator = Legislator.objects.create(
            bioguide_id="A000001",
            first_name="Test",
            last_name="Legislator",
            chamber="House",
            state="MD",
            district="01",
            party="D",
            in_office=True,
        )

    def test_list_legislators_endpoint_returns_200(self) -> None:
        """Test that the legislators list endpoint returns a 200 status code"""
        response = self.client.get("/api/legislators/")
        assert response.status_code == 200

    def test_list_legislators_returns_correct_data(self) -> None:
        """Test that the legislators list endpoint returns the correct data"""
        response = self.client.get("/api/legislators/")
        data = response.json()
        assert len(data) == 1
        assert data[0]["first_name"] == "Test"
        assert data[0]["last_name"] == "Legislator"
        assert data[0]["chamber"] == "House"
        assert data[0]["state"] == "MD"
        assert data[0]["district"] == "01"

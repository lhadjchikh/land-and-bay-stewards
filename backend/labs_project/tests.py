from django.test import Client, TestCase
from django.urls import reverse


class HomePageTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()

    def test_home_view_returns_200(self) -> None:
        """Test that the home view returns a 200 status code"""
        response = self.client.get(reverse("home"))
        assert response.status_code == 200

    def test_home_view_uses_correct_template(self) -> None:
        """Test that the home view uses the index.html template"""
        response = self.client.get(reverse("home"))
        self.assertTemplateUsed(response, "index.html")

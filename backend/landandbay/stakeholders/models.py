from django.db import models


class Stakeholder(models.Model):
    STAKEHOLDER_TYPE_CHOICES = [
        ("farmer", "Farmer"),
        ("waterman", "Waterman"),
        ("business", "Business"),
        ("nonprofit", "Nonprofit"),
        ("other", "Other"),
    ]

    name = models.CharField(max_length=200)
    organization = models.CharField(max_length=200)
    role = models.CharField(max_length=100, blank=True)
    email = models.EmailField()
    state = models.CharField(max_length=2)
    county = models.CharField(max_length=100, blank=True)
    type = models.CharField(max_length=50, choices=STAKEHOLDER_TYPE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"{self.organization} – {self.name}"

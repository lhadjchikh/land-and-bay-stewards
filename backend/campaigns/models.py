from django.db import models
from django.utils import timezone


class PolicyCampaign(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    summary = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return self.title

    def current_bills(self) -> "models.QuerySet[Bill]":
        session = f"{((timezone.now().date().year - 1789) // 2) + 1}th"
        return self.bills.filter(congress_session=session)


class Bill(models.Model):
    CHAMBER_CHOICES = [("House", "House"), ("Senate", "Senate")]

    policy = models.ForeignKey(
        PolicyCampaign,
        on_delete=models.CASCADE,
        related_name="bills",
    )
    number = models.CharField(max_length=50)
    title = models.CharField(max_length=255)
    chamber = models.CharField(max_length=10, choices=CHAMBER_CHOICES)
    congress_session = models.CharField(max_length=10)
    introduced_date = models.DateField()
    status = models.CharField(max_length=100, blank=True)
    url = models.URLField(blank=True)
    is_primary = models.BooleanField(default=False)
    sponsors = models.ManyToManyField(
        "legislators.Legislator",
        related_name="sponsored_bills",
        blank=True,
    )
    cosponsors = models.ManyToManyField(
        "legislators.Legislator",
        related_name="cosponsored_bills",
        blank=True,
    )

    def __str__(self) -> str:
        return f"{self.number} ({self.chamber}, {self.congress_session})"

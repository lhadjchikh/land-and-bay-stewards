from django.db import models


class Legislator(models.Model):
    CHAMBER_CHOICES = [("House", "House"), ("Senate", "Senate")]

    bioguide_id = models.CharField(max_length=10, unique=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    chamber = models.CharField(max_length=10, choices=CHAMBER_CHOICES)
    state = models.CharField(max_length=2)
    district = models.CharField(max_length=2, blank=True)
    is_senior = models.BooleanField(null=True, blank=True)
    party = models.CharField(max_length=1)
    in_office = models.BooleanField(default=True)
    url = models.URLField(blank=True)

    def __str__(self) -> str:
        return f"{self.first_name} {self.last_name} ({self.party}-{self.state})"

    def display_name(self) -> str:
        suffix = ""
        if self.chamber == "Senate":
            suffix = (
                " (Sr.)"
                if self.is_senior
                else " (Jr.)"
                if self.is_senior is not None
                else ""
            )
        elif self.chamber == "House" and self.district:
            suffix = f" – District {self.district}"
        return f"{self.first_name} {self.last_name}{suffix} – {self.state}"

from django.contrib.gis.db.models import MultiPolygonField, PointField
from django.db import models


class Region(models.Model):
    REGION_TYPE_CHOICES = [
        ("state", "State"),
        ("cd119", "Congressional District 119th Congress"),
    ]

    parent = models.ForeignKey(
        "self",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="children",
    )
    geoid = models.CharField(max_length=100, db_index=True)
    name = models.CharField(unique=True, max_length=255)
    label = models.CharField(max_length=255, blank=True, null=True)
    type = models.CharField(choices=REGION_TYPE_CHOICES, max_length=20, db_index=True)
    coords = PointField(
        blank=True,
        null=True,
        spatial_index=True,
        geography=True,
        verbose_name="coordinates",
        help_text="Internal point",
    )
    geom = MultiPolygonField(blank=True, null=True, spatial_index=True)
    geojson = models.JSONField(
        blank=True,
        null=True,
        help_text="Simplified geometry suitable for thematic mapping.",
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["geoid", "type"],
                name="unique__geoid__type",
            ),
        ]

    def __str__(self) -> str:
        return self.name

    def natural_key(self) -> tuple[str]:
        return (self.name,)

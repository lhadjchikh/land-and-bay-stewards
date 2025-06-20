from typing import TYPE_CHECKING

from django.contrib import admin

from .models import Region

if TYPE_CHECKING:
    from django.db.models import QuerySet
    from django.http import HttpRequest


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    """Admin interface for Region model"""

    list_display = ("name", "label", "type", "geoid", "parent", "has_geometry")

    list_filter = ("type", "parent")

    search_fields = ("name", "label", "geoid")

    readonly_fields = ("geoid", "coords", "geom", "geojson")

    fieldsets = (
        ("Basic Information", {"fields": ("name", "label", "type", "geoid", "parent")}),
        (
            "Geographic Data",
            {
                "fields": ("coords", "geom", "geojson"),
                "classes": ("collapse",),
                "description": "Geographic coordinates and geometry data",
            },
        ),
    )

    def has_geometry(self, obj: Region) -> bool:
        """Display whether the region has geometric data"""
        return bool(obj.geom or obj.coords)

    has_geometry.boolean = True
    has_geometry.short_description = "Has Geometry"

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[Region]":
        """Order by type and then name"""
        return super().get_queryset(request).order_by("type", "name")

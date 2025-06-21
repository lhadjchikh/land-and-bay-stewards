from typing import TYPE_CHECKING

from django.contrib import admin

from .models import Legislator

if TYPE_CHECKING:
    from django.db.models import QuerySet
    from django.http import HttpRequest


@admin.register(Legislator)
class LegislatorAdmin(admin.ModelAdmin):
    """Admin interface for Legislator model"""

    list_display = (
        "display_name_short",
        "party",
        "chamber",
        "state",
        "district",
        "in_office",
        "sponsored_bills_count",
        "cosponsored_bills_count",
    )

    list_filter = ("chamber", "party", "state", "in_office", "is_senior")

    search_fields = ("first_name", "last_name", "bioguide_id", "state")

    list_editable = ("in_office",)

    readonly_fields = ("bioguide_id",)

    fieldsets = (
        (
            "Personal Information",
            {"fields": ("bioguide_id", "first_name", "last_name")},
        ),
        (
            "Congressional Information",
            {
                "fields": (
                    "chamber",
                    "state",
                    "district",
                    "is_senior",
                    "party",
                    "in_office",
                ),
            },
        ),
        (
            "Additional Information",
            {
                "fields": ("url",),
                "classes": ("collapse",),
            },
        ),
    )

    def display_name_short(self, obj: Legislator) -> str:
        """Short display name for list view"""
        return f"{obj.first_name} {obj.last_name}"

    display_name_short.short_description = "Name"

    def sponsored_bills_count(self, obj: Legislator) -> int:
        """Display count of sponsored bills"""
        return obj.sponsored_bills.count()

    sponsored_bills_count.short_description = "Sponsored Bills"

    def cosponsored_bills_count(self, obj: Legislator) -> int:
        """Display count of cosponsored bills"""
        return obj.cosponsored_bills.count()

    cosponsored_bills_count.short_description = "Cosponsored Bills"

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[Legislator]":
        """Order by state, chamber, and then name"""
        return (
            super()
            .get_queryset(request)
            .order_by("state", "chamber", "last_name", "first_name")
        )

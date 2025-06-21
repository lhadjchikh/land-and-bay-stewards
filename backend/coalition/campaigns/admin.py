from typing import TYPE_CHECKING

from django.contrib import admin

from .models import Bill, PolicyCampaign

if TYPE_CHECKING:
    from django.db.models import QuerySet
    from django.http import HttpRequest


class BillInline(admin.TabularInline):
    """Inline admin for Bills within PolicyCampaign admin"""

    model = Bill
    extra = 0
    fields = ("number", "title", "chamber", "congress_session", "status", "is_primary")
    readonly_fields = ("congress_session",)


@admin.register(PolicyCampaign)
class PolicyCampaignAdmin(admin.ModelAdmin):
    """Admin interface for PolicyCampaign model"""

    inlines = [BillInline]

    list_display = ("title", "slug", "active", "created_at", "bill_count")

    list_filter = ("active", "created_at")

    search_fields = ("title", "slug", "summary")

    list_editable = ("active",)

    prepopulated_fields = {"slug": ("title",)}

    readonly_fields = ("created_at",)

    fieldsets = (
        ("Campaign Information", {"fields": ("title", "slug", "summary", "active")}),
        (
            "Metadata",
            {
                "fields": ("created_at",),
                "classes": ("collapse",),
            },
        ),
    )

    def bill_count(self, obj: PolicyCampaign) -> int:
        """Display count of associated bills"""
        return obj.bills.count()

    bill_count.short_description = "Bills"

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[PolicyCampaign]":
        """Order by most recently created first"""
        return super().get_queryset(request).order_by("-created_at")


@admin.register(Bill)
class BillAdmin(admin.ModelAdmin):
    """Admin interface for Bill model"""

    list_display = (
        "number",
        "title",
        "policy",
        "chamber",
        "congress_session",
        "status",
        "is_primary",
        "introduced_date",
    )

    list_filter = (
        "chamber",
        "congress_session",
        "is_primary",
        "policy",
        "introduced_date",
    )

    search_fields = ("number", "title", "policy__title")

    list_editable = ("is_primary",)

    readonly_fields = ("congress_session",)

    filter_horizontal = ("sponsors", "cosponsors")

    fieldsets = (
        (
            "Bill Information",
            {
                "fields": (
                    "policy",
                    "number",
                    "title",
                    "chamber",
                    "introduced_date",
                    "status",
                    "url",
                    "is_primary",
                ),
            },
        ),
        (
            "Congressional Information",
            {
                "fields": ("congress_session",),
                "classes": ("collapse",),
            },
        ),
        (
            "Legislators",
            {
                "fields": ("sponsors", "cosponsors"),
                "description": "Legislators who sponsor or cosponsor this bill",
            },
        ),
    )

    def get_queryset(self, request: "HttpRequest") -> "QuerySet[Bill]":
        """Order by policy and then by number"""
        return super().get_queryset(request).order_by("policy", "number")

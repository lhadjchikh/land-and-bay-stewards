from django.contrib import admin

from .models import Endorsement


@admin.register(Endorsement)
class EndorsementAdmin(admin.ModelAdmin):
    list_display = ("stakeholder", "campaign", "public_display", "created_at")
    list_filter = ("public_display", "created_at", "campaign")
    search_fields = (
        "stakeholder__name",
        "stakeholder__organization",
        "campaign__title",
    )
    raw_id_fields = ("stakeholder", "campaign")
    ordering = ("-created_at",)

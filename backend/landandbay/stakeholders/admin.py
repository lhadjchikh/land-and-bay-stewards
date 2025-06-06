from django.contrib import admin

from .models import Stakeholder


@admin.register(Stakeholder)
class StakeholderAdmin(admin.ModelAdmin):
    list_display = ("name", "organization", "type", "state", "county", "created_at")
    list_filter = ("type", "state", "created_at")
    search_fields = ("name", "organization", "email", "county")
    ordering = ("-created_at",)

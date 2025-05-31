from django.apps import AppConfig


class CampaignsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "landandbay.campaigns"
    label = "campaigns"  # Use original table names

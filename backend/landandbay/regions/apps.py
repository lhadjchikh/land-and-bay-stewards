from django.apps import AppConfig


class RegionsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "landandbay.regions"
    label = "regions"  # Use original table names

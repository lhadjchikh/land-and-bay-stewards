from django.apps import AppConfig


class RegionsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "coalition.regions"
    label = "regions"  # Use original table names

from django.apps import AppConfig


class LegislatorsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "landandbay.legislators"
    label = "legislators"  # Use original table names

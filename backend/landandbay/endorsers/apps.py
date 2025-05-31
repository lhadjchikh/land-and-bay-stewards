from django.apps import AppConfig


class EndorsersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "landandbay.endorsers"
    label = "endorsers"  # Use original table names

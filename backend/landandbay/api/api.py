from django.http import HttpRequest, JsonResponse
from ninja import NinjaAPI

from landandbay.core.views import health_check as health_check_view

from . import campaigns, endorsements, legislators, stakeholders

api = NinjaAPI(version="1.0")

api.add_router("/campaigns/", campaigns.router)
api.add_router("/stakeholders/", stakeholders.router)
api.add_router("/endorsements/", endorsements.router)
api.add_router("/legislators/", legislators.router)


@api.get("/health/", tags=["Health"])
def api_health_check(request: HttpRequest) -> JsonResponse:
    """Health check endpoint for API monitoring and container health checks"""
    # Re-use the Django view health check function
    return health_check_view(request)

from django.http import HttpRequest, JsonResponse
from ninja import NinjaAPI

from coalition.core.views import health_check as health_check_view

from . import campaigns, endorsements, homepage, legislators, stakeholders

api = NinjaAPI(version="1.0")

api.add_router("/campaigns/", campaigns.router)
api.add_router("/stakeholders/", stakeholders.router)
api.add_router("/endorsements/", endorsements.router)
api.add_router("/legislators/", legislators.router)
api.add_router("/homepage/", homepage.router)


@api.get("/health/", tags=["Health"])
def api_health_check(request: HttpRequest) -> JsonResponse:
    """Health check endpoint for API monitoring and external tools"""
    # Re-use the Django view health check function
    return health_check_view(request)

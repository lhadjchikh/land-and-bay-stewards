from ninja import NinjaAPI

from . import campaigns, endorsers, legislators
from landandbay.core.views import health_check as health_check_view

api = NinjaAPI(version="1.0")

api.add_router("/campaigns/", campaigns.router)
api.add_router("/endorsers/", endorsers.router)
api.add_router("/legislators/", legislators.router)

@api.get("/health/", tags=["Health"])
def api_health_check(request):
    """Health check endpoint for API monitoring and container health checks"""
    # Re-use the Django view health check function
    return health_check_view(request)

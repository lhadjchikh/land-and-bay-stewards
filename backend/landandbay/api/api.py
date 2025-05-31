from ninja import NinjaAPI

from . import campaigns, endorsers, legislators

api = NinjaAPI(version="1.0")

api.add_router("/campaigns/", campaigns.router)
api.add_router("/endorsers/", endorsers.router)
api.add_router("/legislators/", legislators.router)

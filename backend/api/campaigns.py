from django.http import HttpRequest
from ninja import Router

from campaigns.models import PolicyCampaign

from .schemas import PolicyCampaignOut

router = Router()


@router.get("/", response=list[PolicyCampaignOut])
def list_campaigns(request: HttpRequest) -> list[PolicyCampaign]:
    return PolicyCampaign.objects.all()

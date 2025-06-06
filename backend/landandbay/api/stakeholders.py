from django.http import HttpRequest
from ninja import Router

from landandbay.stakeholders.models import Stakeholder

from .schemas import StakeholderOut

router = Router()


@router.get("/", response=list[StakeholderOut])
def list_stakeholders(request: HttpRequest) -> list[Stakeholder]:
    return Stakeholder.objects.all()

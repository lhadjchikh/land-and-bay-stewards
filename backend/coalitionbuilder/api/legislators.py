from django.http import HttpRequest
from ninja import Router

from coalitionbuilder.legislators.models import Legislator

from .schemas import LegislatorOut

router = Router()


@router.get("/", response=list[LegislatorOut])
def list_legislators(request: HttpRequest) -> list[Legislator]:
    return Legislator.objects.all()

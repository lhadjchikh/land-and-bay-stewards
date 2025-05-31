from django.http import HttpRequest
from ninja import Router

from landandbay.endorsers.models import Endorser

from .schemas import EndorserOut

router = Router()


@router.get("/", response=list[EndorserOut])
def list_endorsers(request: HttpRequest) -> list[Endorser]:
    return Endorser.objects.all()

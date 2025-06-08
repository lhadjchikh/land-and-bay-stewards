from django.http import HttpRequest
from ninja import Router

from coalition.endorsements.models import Endorsement

from .schemas import EndorsementOut

router = Router()


@router.get("/", response=list[EndorsementOut])
def list_endorsements(request: HttpRequest) -> list[Endorsement]:
    return Endorsement.objects.select_related("stakeholder", "campaign").all()

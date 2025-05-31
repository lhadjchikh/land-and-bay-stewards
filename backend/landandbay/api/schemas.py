from ninja import Schema


class PolicyCampaignOut(Schema):
    id: int
    title: str
    slug: str
    summary: str


class EndorserOut(Schema):
    id: int
    name: str
    organization: str
    state: str
    type: str


class LegislatorOut(Schema):
    id: int
    first_name: str
    last_name: str
    chamber: str
    state: str
    district: str | None = None
    is_senior: bool | None = None

from datetime import datetime

from ninja import Schema


class PolicyCampaignOut(Schema):
    id: int
    title: str
    slug: str
    summary: str


class StakeholderOut(Schema):
    id: int
    name: str
    organization: str
    role: str
    email: str
    state: str
    county: str
    type: str
    created_at: datetime


class EndorsementOut(Schema):
    id: int
    stakeholder: StakeholderOut
    campaign: PolicyCampaignOut
    statement: str
    public_display: bool
    created_at: datetime


class LegislatorOut(Schema):
    id: int
    first_name: str
    last_name: str
    chamber: str
    state: str
    district: str | None = None
    is_senior: bool | None = None

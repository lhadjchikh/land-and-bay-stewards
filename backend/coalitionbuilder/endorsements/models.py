from django.db import models

from coalitionbuilder.stakeholders.models import Stakeholder


class Endorsement(models.Model):
    stakeholder = models.ForeignKey(
        Stakeholder,
        on_delete=models.CASCADE,
        related_name="endorsements",
    )
    campaign = models.ForeignKey(
        "campaigns.PolicyCampaign",
        on_delete=models.CASCADE,
        related_name="endorsements",
    )
    statement = models.TextField(blank=True)
    public_display = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ["stakeholder", "campaign"]

    def __str__(self) -> str:
        return f"{self.stakeholder} endorses {self.campaign}"

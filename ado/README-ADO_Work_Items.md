This builds on work started by **Rob Pleau** (many thanks to Rob for blazing the trail on this):
https://lacework.atlassian.net/wiki/spaces/~6234fd4f1c09d20070159a15/pages/2644967840/Lacework+Alerts+Events+to+Azure+DevOps+Boards+Work+Items

This repo provides a runbook that:
- creates a more nicely formatted event in ADO Work Items that includes specific resources in violation of compliance events.  This involves a callback to the Lacework API that is not included in Rob's original script.
- includes the Lacework event link formatted as a clickable link.  The URL is included in the original runbook, but it is not formatted as a clickable link.
- includes a link in the Work Item to our public policy docs where possible to streamline remediation, especially for compliance events.


**High-Level Overview of the Integration**

- Lacework sends a webhook to an Azure Automation Account configured with a webhook listener.
- The Automation Account triggers a runbook when it receives a webhook.  That runbook is provided in this repo:  `automation-runbook.ps1`
- The runbook translates the webhook data into a nicely formatted ADO Work Item and uses the ADO API to send the event to ADO as a Work Item.

The Azure Automation Account allows you to configure Variables as Shared Resources (in the pane on the left).  The following variables must be set for the provided runbook:
- ADO_ORG - the name of the ADO org where you want to create Work Items
- ADO_PROJECT - the name of the ADO project (in the ADO org) where you want to create Work Items
- ADO_PAT - an ADO personal access token needed for the ADO API
- LW_API_KEY (optional) - a Lacework API key ID configured in the Lacework account that is sending webhooks.  When receiving compliance events, this enables retrieving the resources in violation via the Lacework API.  (These resources are not included in the webhook data).
- LW_API_SECRET (optional) - this is paired with the Lacework API key ID above for retrieving resources in violation of compliance.  Both the key ID and secret are required to call the Lacework API.

If you omit the LW_API variables, a Work Item is still created for compliance events without the resources in violation.  You will then need to click the Lacework event URL in the Work Item to go into the Lacework UI to see the full details of the compliance event (with resources).

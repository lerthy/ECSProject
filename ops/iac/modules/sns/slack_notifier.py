import json
import os
import urllib.request

def handler(event, context):
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    for record in event["Records"]:
        sns = record["Sns"]
        message = sns["Message"]
        subject = sns.get("Subject", "SNS Alert")
        slack_data = {
            "text": f"*{subject}*\n{message}"
        }
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(slack_data).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(req)
        except Exception as e:
            print(f"Slack notification failed: {e}")
    return {"statusCode": 200}

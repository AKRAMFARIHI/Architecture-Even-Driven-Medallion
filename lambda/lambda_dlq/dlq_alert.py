import boto3
import json
import os

sns = boto3.client("sns")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    print("Message DLQ reçu :")
    print(event)

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="DLQ ALERT",
        Message=json.dumps({
            "status": "ERROR",
            "dlq_message": event
        })
    )

    return {"status": "ok"}
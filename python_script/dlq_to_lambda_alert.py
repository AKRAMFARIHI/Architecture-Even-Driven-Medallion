import boto3
import json

sqs_client = boto3.client("sqs", region_name="us-east-1", endpoint_url="http://localhost:4566")
lambda_client = boto3.client('lambda', endpoint_url="http://localhost:4566")

dlq_url = sqs_client.get_queue_url(QueueName="evaluation-dlq")["QueueUrl"]

while True:
    resp = sqs_client.receive_message(QueueUrl=dlq_url, MaxNumberOfMessages=1, WaitTimeSeconds=10)
    messages = resp.get('Messages', [])
    for msg in messages:
        raw_body = msg["Body"]

        print(raw_body)
        payload = {
            "source": "DLQ",
            "raw_message": raw_body
        }

        lambda_client.invoke(
            FunctionName='dlq_alert',
            InvocationType='Event',
            Payload=json.dumps(payload).encode('utf-8')
        )
        sqs_client.delete_message(QueueUrl=dlq_url, ReceiptHandle=msg['ReceiptHandle'])







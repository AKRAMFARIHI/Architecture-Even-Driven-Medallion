import boto3
import json

lambda_client = boto3.client('lambda', endpoint_url="http://localhost:4566")
sqs = boto3.client(
    "sqs",
    region_name="us-east-1",
    endpoint_url="http://localhost:4566"  # <-- important pour LocalStack
)

queue_url = sqs.get_queue_url(QueueName="evaluation-silver-to-gold-queue")["QueueUrl"]

while True:
    resp = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1, WaitTimeSeconds=1)
    messages = resp.get('Messages', [])
    for msg in messages:
        payload = json.loads(msg['Body'])
        lambda_client.invoke(
            FunctionName='dispatcher_to_lambda_gold',
            InvocationType='Event',   # IMPORTANT
            Payload=json.dumps(payload).encode('utf-8')
        )
        # Supprimer le message après traitement
        sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=msg['ReceiptHandle'])

import json

def lambda_handler(event, context):
    for record in event['Records']:
        message = record['Sns']['Message']
        print(f"[SNS] Message reçu : {message}")
    return {"statusCode": 200}

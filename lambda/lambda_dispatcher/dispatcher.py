import boto3
import json
lambda_client = boto3.client('lambda')


PRIX_M2_FUNCTION = "prix_m2_par_ville_annee"
NOMBRE_BIENS_FUNCTION = "nombre_de_biens"
def lambda_handler(event, context):
    for record in event.get("Records", [event]):
        print(record)
        payload = {
                "bucket": record["s3"]["bucket"]["name"],
                "key": record["s3"]["object"]["key"]
            }

        lambda_client.invoke(
            FunctionName = PRIX_M2_FUNCTION, 
            InvocationType = "Event", 
            Payload = json.dumps(payload).encode('utf-8')
        )

        lambda_client.invoke(
            FunctionName = NOMBRE_BIENS_FUNCTION, 
            InvocationType = "Event", 
            Payload = json.dumps(payload).encode('utf-8')
        )
    return {
        "status" : "ok"
    }

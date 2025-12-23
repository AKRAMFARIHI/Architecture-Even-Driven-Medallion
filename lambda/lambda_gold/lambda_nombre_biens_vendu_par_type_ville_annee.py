import boto3
import pandas as pd
import os
import json
import time
import datetime
from utils import extract_file_body_and_key , add_year_colonne , read_csv_gzip , transforme_to_csv_and_compresse , upload_to_gold


s3_client = boto3.client('s3')
sns_client = boto3.client("sns")
cloud_watch_client = boto3.client('cloudwatch')
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    file_processed = 0
    file_failed = 0
    records_processed = 0
    try:
        start_time = time.time()
        print(event)
        body , key , bucket_name = extract_file_body_and_key(event)
        year = key.split('/')[-2]
        df = read_csv_gzip(body)
        if df == None:
             file_failed = 1
        else:
             file_processed = 1
             records_processed = len(df)
        df = extract_important_colonnes(df)
        df = add_year_colonne(df)
        df = agregate_count_nomber_of_houses(df)

        print(df.head())
        print(df.shape)

        file_compresset_to_gzip = transforme_to_csv_and_compresse(df, f"nombre_bien_vendu_{year}")
        upload_to_gold(f"nombre_bien_vendu_{year}", year, file_compresset_to_gzip, "evaluation-bucket-gold")
        end_time = time.time()
        time_processing = end_time - start_time

        cloud_watch_client.put_metric_data(
            Namespace = 'Gold_first_lambda/DataPipeline', 
            MetricData= [
                
                {
                    'MetricName': 'ProcessingTime', 
                    'Value': time_processing, 
                    'Unit': 'Seconds', 
                    'Timestamp': datetime.datetime.now()
                } , 
                {
                    "MetricName": "Executions",
                    "Value": 1,
                    "Unit": "Count" ,
                    "Timestamp" : datetime.datetime.now()
                } ,
                {
                    "MetricName": "FilesProcessed",
                    "Value": file_processed,
                    "Unit": "Count"
                } ,
                {
                    "MetricName": "FileFailed",
                    "Value": file_failed,
                    "Unit": "Count"
                } ,
                {
                    "MetricName": "RecordsProcessed",
                    "Value": records_processed,
                    "Unit": "Count"
                } 
            ]
        )

        sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="Lambda Gold",
        Message=json.dumps({
            "status": "Succes",
            "dlq_message": "Traitement du lambda nombre de biens vendu est terminer !"
            })
        )

        return {
        'statusCode' : 200 ,
        'body' : "Upload to gold succes !"
        }
    
    except Exception as e:
        print(f"Erreur ! , {e}")
        cloud_watch_client.put_metric_data(
            Namespace = 'Gold_first_lambda/Pipeline', 
            MetricData = [
                {
                    'MetricName': 'Error', 
                    'Value' : 1 ,
                    'Unit': 'Count', 
                    'Timestamp': datetime.datetime.now()
                }
            ]
        )
        raise

  
def extract_important_colonnes(df):
    cols_nb_biens = ["date_mutation", "commune", "type_local"]
    df = df[[c for c in cols_nb_biens if c in df.columns]]
    return df

def agregate_count_nomber_of_houses(df):
    nb_biens_agg = (df.groupby(["annee", "commune", "type_local"]).size().reset_index(name="nombre_ventes"))
    return nb_biens_agg

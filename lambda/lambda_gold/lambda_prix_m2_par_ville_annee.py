import boto3
import pandas as pd
import json
import os
import time
import datetime
from utils import extract_file_body_and_key, add_year_colonne , read_csv_gzip , transforme_to_csv_and_compresse , upload_to_gold

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
cloud_watch_client = boto3.client('cloudwatch')
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
def lambda_handler(event, context):
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
        df= add_price_m2_colonne(df)

        df = agregat_year_and_city(df)

        print(df.head())
        print(df.columns)
        print(df.shape)

        file_compresset_to_gzip = transforme_to_csv_and_compresse(df, f"prix_m2_{year}")
        upload_to_gold(f"prix_m2_{year}", year, file_compresset_to_gzip, "evaluation-bucket-gold")
        end_time = time.time()
        time_processing = end_time - start_time

        cloud_watch_client.put_metric_data(
            Namespace = 'Gold_second_lambda/DataPipeline', 
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
                    "MetricName": "FilesProcessed",
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
            "dlq_message": "Traitement du lambda prix m2 est terminer !"
            })
        )

        return {
            'statusCode' : 200 ,
            'body' : "Upload to gold succes !"
        }
    except Exception as e :
         print(f"Erreur ! , {e}")
         cloud_watch_client.put_metric_data(
            Namespace = 'Gold_second_lambda/Pipeline', 
            MetricData = [
                {
                    'MetricName': 'Error', 
                    'Value' : 1 ,
                    'Unit': 'Count', 
                    'Timestamp': datetime.datetime.now()
                }
            ]
        )


    
def extract_important_colonnes(df):
    cols_prix_m2 = ["date_mutation", "commune", "code_postal", "valeur_fonciere", "surface_reelle_bati"]
    df = df[cols_prix_m2]
    return df

def add_price_m2_colonne(df):
    df["prix_m2"] = df["valeur_fonciere"] / df["surface_reelle_bati"]
    return df

def agregat_year_and_city(df):
    prix_m2_agg = (df.groupby(["annee", "commune", "code_postal"])["prix_m2"].mean().reset_index())
    prix_m2_agg = prix_m2_agg.rename(columns={"prix_m2": "prix_m2_moyen"})

    return prix_m2_agg

    
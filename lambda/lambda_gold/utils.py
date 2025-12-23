import boto3
import pandas as pd
from io import BytesIO
import json
import os
from urllib.parse import unquote

s3_client = boto3.client('s3')
def read_csv_gzip(file):
    try:
        buffer = BytesIO(file)
        df = pd.read_csv(buffer, sep=';', compression='gzip', low_memory=False)
        print(f"Fichier est chargé avec succès !")
        return df
    except Exception as e :
        print(f"Erreur lors de la lecture du fichier , {e}")
        return None
    

def extract_file_body_and_key(payload):
    bucket_name = payload['bucket']
    key = unquote(payload['key'])
    get_object = s3_client.get_object(Bucket=bucket_name, Key=key)
    get_file_content = get_object['Body'].read()
    return get_file_content , key , bucket_name

def add_year_colonne(df):
    df["annee"] = pd.to_datetime(df["date_mutation"]).dt.year
    return df

def transforme_to_csv_and_compresse(df, file_name):
    output_file_compresse = f"/tmp/{file_name}.csv.gzip"
    df.to_csv(output_file_compresse ,sep=';', index=False, compression='gzip')
    return output_file_compresse

def upload_to_gold(filename, year , compresse_compressed_to_csv_gzip, bucket_name):
    key = f"gold/{year}/{filename}.csv.gzip"
    if os.path.getsize(compresse_compressed_to_csv_gzip) > 0 :
        s3_client.upload_file(compresse_compressed_to_csv_gzip, bucket_name, key)
        print(f"Upload file {filename} to Gold folder !")
        return True 





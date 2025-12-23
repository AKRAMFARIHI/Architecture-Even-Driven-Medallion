import boto3
import zipfile
import pandas as pd
import numpy
import datetime
import time
import io
import os
import re
import unicodedata
from urllib.parse import unquote


s3_client = boto3.client('s3')
cloud_watch_client = boto3.client('cloudwatch')
def lambda_handler(event, context):
    records_processed = 0
    files_processed = 0
    files_failed = 0
    try:
        # Start time 
        start_time = time.time()
        # juste pour test 
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        key = unquote(event['Records'][0]['s3']['object']['key'])
        print('the key is : ', key)
        print('the bucket name is ', bucket_name)

        print("Objet recuperer ! ", key)
        files_processed = 1
        file_name_with_extension = key.split('/')[-1]
        file_name_without_extension = file_name_with_extension.split('.')[-3]
        year = key.split('/')[-2]

        response = s3_client.get_object(Bucket=bucket_name, Key=key)
        if response == None:
            files_failed = 1

        raw_data = response['Body'].read()

        contenu_txt = decompresse_file_zip(raw_data)
        lignes = contenu_txt.splitlines()[:51]
        

        colonne_ligne = lignes[0]
        new_colonnes = []
        for colonne in colonne_ligne.split('|'):
            new_colonne = snake_case(colonne)
            new_colonnes.append(new_colonne)

        print(new_colonnes)
        df = force_data_type(lignes, new_colonnes)
        records_processed = len(df)
        print(df.head())
        print("data types are changed !")
        print(df.dtypes)
        df = clean_data(df)

        print("data is successefuly cleaned !")

        file_compresset_to_gzip = transforme_to_csv_and_compresse(df, file_name_without_extension)
        upload_to_silver(file_name_without_extension, year, file_compresset_to_gzip, "evaluation-bucket-silver")
        # End time
        end_time = time.time()
        time_processes = end_time - start_time

        cloud_watch_client.put_metric_data(
            Namespace = 'Silver/DataPipeline', 
            MetricData= [
                
                {
                    'MetricName': 'ProcessingTime', 
                    'Value': time_processes, 
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
                    "Value": files_processed,
                    "Unit": "Count"
                } ,
                {
                    "MetricName": "FilesProcessed",
                    "Value": files_failed,
                    "Unit": "Count"
                } ,
                {
                    "MetricName": "RecordsProcessed",
                    "Value": records_processed,
                    "Unit": "Count"
                } 
            ]
        )

        return {
        'statusCode' : 200 ,
        'body' : "Upload to silver succes !"
        }

        
    except Exception as e:
        print(f"Erreur ! , {e}")
        cloud_watch_client.put_metric_data(
            Namespace = 'Silver/DataPipeline', 
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




# Décompresser les fichiers zip 
def decompresse_file_zip(raw_data):
    with zipfile.ZipFile(io.BytesIO(raw_data)) as z:
        with z.open(z.namelist()[0]) as f:
            contenu = f.read().decode('utf-8')
    return contenu
# Organiser les entêtes des colonnes
def snake_case(colonne):
    # Pour gérer les accents 
    colonne = unicodedata.normalize('NFKD', colonne).encode('ASCII','ignore').decode('utf-8')
    # Pour remplacer les espaces et les caractère spéciaux par '_'
    colonne = re.sub(r'[^0-9a-zA-Z]+','_', colonne)
    # Supprimer les underscore au début et à la fin !
    colonne = colonne.strip('_')
    # Transformer les colonne majuscule en minuscule
    colonne = colonne.lower()
    return colonne

# Traiter les types de chaque colonne 
def force_data_type(lignes, new_colonnes):
    print("yes, les lignes sont pas vides !")

    # Extraire les données, ignorer les lignes vides
    data = [ligne.split('|') for ligne in lignes[1:] if ligne.strip()]
    df = pd.DataFrame(data, columns=new_colonnes) if data else pd.DataFrame(columns=new_colonnes)

    # Colonne de type date
    if 'date_mutation' in df.columns:
        df['date_mutation'] = pd.to_datetime(df['date_mutation'], errors='coerce', dayfirst=True)

    # Colonnes numériques de type float
    colonnes_float = [
        'valeur_fonciere', 'surface_carrez_du_1er_lot','surface_carrez_du_2eme_lot', 
        'surface_carrez_du_3eme_lot', 'surface_carrez_du_4eme_lot', 'surface_carrez_du_5eme_lot' 
        , 'surface_reelle_bati', 'nombre_pieces_principales', 'surface_terrain'
    ]
    
    for col in colonnes_float:
        if col in df.columns:
            df[col] = (df[col].astype(str).str.strip().str.replace(',', '.', regex=False).replace('',pd.NA))
            df[col] = pd.to_numeric(df[col], errors='coerce')

    # Colonnes de type int
    colonnes_int = ['nombre_de_lots']

    for col in colonnes_int:
        if col in df.columns:
            df[col] = (pd.to_numeric(df[col], errors='coerce').astype('Int64'))

    # Colonnes de type string
    colonnes_string = [
        'identifiant_de_document', 'reference_document', 'nature_mutation', 'no_disposition', 'code_postal', 
        'code_departement', 'code_commune', 'no_voie', 'b_t_q', 'type_de_voie', 'code_voie', 'voie', 
        'commune', 'prefixe_de_section', 'section', 'no_plan', 'no_volume', '1_articles_cgi', '2_articles_cgi', '3_articles_cgi',
        '4_articles_cgi', '5_articles_cgi', '1er_lot', '2eme_lot', '3eme_lot', '4eme_lot', '5eme_lot', 
        'code_type_local', 'type_local', 'identifiant_local', 'nature_culture', 'nature_culture_speciale'
    ]
    
    for col in colonnes_string:
        if col in df.columns:
            df[col] = df[col].astype('string').str.strip().replace('', pd.NA)

    return df


# Traitement simple des données 
def clean_data(df):
    # Remplacer les chaînes vides par Nan
    df = df.replace('', numpy.nan)

    # Remplacer les valeurs manquantes par la médiane 
    colonnes_num = ['valeur_fonciere', 'surface_reelle_bati', 'surface_terrain', 'nombre_pieces_principales']
    for col in colonnes_num:
        if col in df.columns and not df[col].isna().all():
            df[col] = df[col].fillna(df[col].median())

    if 'surface_reelle_bati' in df.columns:
        df = df[df['surface_reelle_bati'] > 0]
        
    if 'valeur_fonciere' in df.columns:
        df = df[df['valeur_fonciere'] > 0]

    # Gerer les valeurs aberantes pour la colonnes 'valeur_fonciere'
    q1 = df['valeur_fonciere'].quantile(0.25)
    q3 = df['valeur_fonciere'].quantile(0.75)
    iqr = q3 - q1 

    df = df[
        (df['valeur_fonciere'] >= q1 - 1.5 * iqr) &
        (df['valeur_fonciere'] <= q3 + 1.5 * iqr)
    ]

    return df

# Transformer le dataframe sous forme csv 
def transforme_to_csv_and_compresse(df, file_name_without_extension):
    output_file_compresse = f"/tmp/{file_name_without_extension}.csv.gzip"
    df.to_csv(output_file_compresse, sep=';', index=False, compression='gzip')
    return output_file_compresse


def upload_to_silver(filename, year , compresse_compressed_to_csv_gzip, bucket_name):
    key = f"silver/{year}/{filename}.csv.gzip"
    if os.path.getsize(compresse_compressed_to_csv_gzip) > 0 :
        s3_client.upload_file(compresse_compressed_to_csv_gzip, bucket_name, key)
        print(f"Upload file {filename} to Silver folder !")
        return True 











    



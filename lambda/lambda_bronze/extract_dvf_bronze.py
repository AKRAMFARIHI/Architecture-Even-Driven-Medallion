import boto3
import os
import datetime
import time
from urllib.request import urlopen

# List les noms et les urls des fichiers
list_of_names_and_urls_files = {
    "valeursfoncieres-2025-s1.txt.zip" : "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234902/valeursfoncieres-2025-s1.txt.zip" ,
    "valeursfoncieres-2024.txt.zip" : "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234857/valeursfoncieres-2024.txt.zip" ,
    "valeursfoncieres-2023.txt.zip" : "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234851/valeursfoncieres-2023.txt.zip" ,
    "valeursfoncieres-2022.txt.zip" : "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234844/valeursfoncieres-2022.txt.zip" ,
    "valeursfoncieres-2021.txt.zip" : "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234836/valeursfoncieres-2021.txt.zip"
}
years = ["2025" , "2024" , "2023" , "2022" , "2021"]
#Acceder au service S3
s3_client = boto3.client('s3')
cloud_watch_client = boto3.client('cloudwatch')
temp_dir = "/tmp/data_temp"
os.makedirs(temp_dir, exist_ok=True)

# télécharger les fichiers et les stoker dans un dossier temporaire
def download_file(file_name , url):
    path_to_file = os.path.join(temp_dir, file_name)
    try:
        with urlopen(url) as response, open(path_to_file, 'wb') as out_file:
            while chunk := response.read(1024*1024):
                out_file.write(chunk)
        print(f"Téléchargement reussi ! : {file_name}")
        return path_to_file
    except Exception as e:
        print(f"Erreur fichier n'est pas télécharger ! {e}")
        return None

    
# supprimer les fichiers dans le dossier data_temp 
def delete_file(file):
    chemin_complet = os.path.join(temp_dir, file)
    os.remove(chemin_complet)

# Fonction Lambda
def lambda_handler(event, context):
    i = 0
    num_files_upload = 0
    num_files_failed = 0
    try:
        #Start lambda function
        start_time = time.time()

        bucket_name = "evaluation-bucket-bronze"
        for file_name , url in list_of_names_and_urls_files.items():
            local_path = download_file(file_name, url)
            year  = years[i]
            i = i + 1 
            if local_path:
                key = f"bronze/year={year}/{file_name}" 
                try:
                    s3_client.upload_file(local_path, bucket_name, key)
                    num_files_upload = num_files_upload + 1
                    print(f"Téléversement réussi : {key}")
                except Exception as e:
                    print(f"Erreur upload {file_name} :", e)
                    num_files_failed = num_files_failed + 1

        # Supprimer les fichiers télécharger qui sont dans le dossier temporaire
        for file in os.listdir(temp_dir):
            delete_file(file)
        
        # calculer le taux d'erreur
        errorsRate = num_files_failed / max(num_files_upload + num_files_failed , 1)

        end_time = time.time()
        time_processing = end_time - start_time
        # Put metric number of files uploaded to Bronze Folder
        cloud_watch_client.put_metric_data(
            Namespace='Bronze/DataPipeline' ,
            MetricData= [
                {
                    'MetricName' : 'Executions',
                    'Value' : 1 ,
                    'Unit' : 'Count',
                    'Timestamp' : datetime.datetime.now()  

                } ,
                {
                    'MetricName' : 'TimeProcesses' ,
                    'Value': time_processing ,
                    'Unit': 'Seconds' ,
                    'Timestamp': datetime.datetime.now()
                } ,
                {
                    'MetricName': 'FilesUploaded',
                    'Value': num_files_upload, 
                    'Unit': 'Count' ,
                    'Timestamp': datetime.datetime.now()
                } ,
                {
                    'MetricName': 'FilesFailed', 
                    'Value': num_files_failed, 
                    'Unit': 'Count', 
                    'Timestamp': datetime.datetime.now()
                } , 
                {
                    'MetricName': 'ErrorsRate', 
                    'Value': errorsRate ,
                    'Unit': 'None', 
                    'Timestamp': datetime.datetime.now()
                }
            ]
        )
        return {
            'statusCode' : 200 ,
            'body' : "Upload succes !"
        }
    except Exception as e : 
        cloud_watch_client.put_metric_data(
            Namespace='Bronze/DataPipeline',
            MetricData=[
                {
                    'MetricName': 'Errors', 
                    'Value': 1, 
                    'Unit': 'Count', 
                    'Timestamp': datetime.datetime.now()
                }
            ]
        )

        


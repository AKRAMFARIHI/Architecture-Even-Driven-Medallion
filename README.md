Mon projet – Pipeline Event-Driven & Medallion

Ce fichier README décrit les étapes nécessaires pour démarrer, déployer et tester le projet en local à l’aide de LocalStack Pro et Terraform.

✅ Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

Un token LocalStack Pro valide (LOCALSTACK_AUTH_TOKEN)

Docker installé et fonctionnel

Terraform installé

Python 3.11

Un terminal (Linux / macOS recommandé)

🚀 Démarrage de LocalStack Pro

Dans un premier terminal, lancez LocalStack Pro avec la commande suivante :

docker run --rm -it \
  -p 127.0.0.1:4566:4566 \
  -p 127.0.0.1:4510-4559:4510-4559 \
  -e LOCALSTACK_AUTH_TOKEN=<TOKEN-ID> \
  -e ENFORCE_IAM=1 \
  -e DEBUG=1 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack-pro


⚠️ Remplacez <TOKEN-ID> par votre token LocalStack Pro.

🏗️ Déploiement de l’infrastructure (Terraform)

Dans un deuxième terminal, positionnez-vous dans le dossier Terraform du projet, puis exécutez :

terraform apply


Cette commande déploie l’ensemble des services AWS simulés :

Buckets S3 (Bronze, Silver, Gold)

Lambdas

SQS + DLQ

SNS

Permissions IAM

👂 Démarrage des écouteurs SQS / DLQ

Dans un troisième terminal, deux écouteurs doivent être lancés manuellement.
Ces écouteurs sont des scripts Python exécutés en arrière-plan.

Rôle des écouteurs

Écouteur SQS → Lambda Dispatcher
Transfère les messages depuis la file SQS vers la Lambda Dispatcher.

Écouteur DLQ → SNS
Transfère les messages en erreur depuis la DLQ vers le topic SNS.

Lancement des écouteurs

Accédez au dossier suivant :

cd ../Architecture-Event-Driven-Medallion/python_script


Lancez les scripts avec nohup :

nohup python3.11 sqs_to_lambda_dispatcher.py > dispatcher.log 2>&1 &
nohup python3.11 dlq_to_lambda_alert.py > alert.log 2>&1 &

Vérification des scripts actifs

Pour vérifier que les scripts sont bien en cours d’exécution :

ps aux | grep sqs_to_lambda_dispatcher.py
ps aux | grep dlq_to_lambda_alert.py

▶️ Lancement du pipeline

Une fois l’infrastructure déployée et les écouteurs actifs :

Accédez à la console AWS (LocalStack)

Sélectionnez la Lambda :

evaluation_ingestion_to_bronze

Déclenchez-la manuellement

Cette Lambda démarre l’ingestion des données DVF et lance automatiquement l’ensemble du pipeline.

⏳ Temps d’exécution

⚠️ Le traitement des fichiers DVF est long (volumineux).
Il est normal que le pipeline prenne plusieurs minutes avant de produire les résultats dans le bucket S3 Gold.
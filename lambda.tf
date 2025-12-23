# Package de la lambda extract_dvf_bronze
data "archive_file" "extract_dvf_bronze" {
    type = "zip"
    source_file = "${path.module}/lambda/lambda_bronze/extract_dvf_bronze.py"
    output_path = "${path.module}/lambda/lambda_bronze/extract_dvf_bronze.zip"
}

# Package de la lambda normalize_bronze_to_silver
data "archive_file" "normalize_bronze_to_silver"{
    type = "zip"
    source_file = "${path.module}/lambda/lambda_silver/normalize_bronze_to_silver.py"
    output_path = "${path.module}/lambda/lambda_silver/normalize_bronze_to_silver.zip"
}

# Package de la lambda test
data "archive_file" "test"{
    type = "zip"
    source_file = "${path.module}/lambda/lambda_test/test.py"
    output_path = "${path.module}/lambda/lambda_test/test.zip"
}

#Package de la lambda dlq_alert 
data "archive_file" "dlq_alert" {
    type = "zip"
    source_file = "${path.module}/lambda/lambda_dlq/dlq_alert.py"
    output_path = "${path.module}/lambda/lambda_dlq/dlq_alert.zip"
}

# Package de la lambda sns logging 
data "archive_file" "sns_logging" {
    type= "zip"
    source_file = "${path.module}/lambda/lambda_logging/lambda_logging.py"
    output_path = "${path.module}/lambda/lambda_logging/lambda_logging.zip"
}

# Package de la lambda lambda_prix_m2_par_ville_annee    source_file = "${path.module}/lambda/lambda_gold/lambda_prix_m2_par_ville_annee.py"
data "archive_file" "lambda_prix_m2_par_ville_annee" {
    type = "zip"
    source {
        content = file("${path.module}/lambda/lambda_gold/lambda_prix_m2_par_ville_annee.py")
        filename = "lambda_prix_m2_par_ville_annee.py"
    }

    source {
        content  = file("${path.module}/lambda/lambda_gold/utils.py")
        filename = "utils.py"
    }

    output_path = "${path.module}/lambda/lambda_gold/lambda_prix_m2_par_ville_annee.zip"
}

# Package de la lambda lambda_nombre_biens_vendu_par_type_ville_annee  source_file = "${path.module}/lambda/lambda_gold/lambda_nombre_biens_vendu_par_type_ville_annee.py"
data "archive_file" "lambda_nombre_biens_vendu_par_type_ville_annee"{
    type = "zip"
    source {
        content  = file("${path.module}/lambda/lambda_gold/lambda_nombre_biens_vendu_par_type_ville_annee.py")
        filename = "lambda_nombre_biens_vendu_par_type_ville_annee.py"
    }

    source {
        content  = file("${path.module}/lambda/lambda_gold/utils.py")
        filename = "utils.py"
    }
    output_path = "${path.module}/lambda/lambda_gold/lambda_nombre_biens_vendu_par_type_ville_annee.zip"
}

# Package de la lambda disparch
data "archive_file" "lambda_dispatcher"{
    type = "zip"
    source_file = "${path.module}/lambda/lambda_dispatcher/dispatcher.py"
    output_path = "${path.module}/lambda/lambda_dispatcher/dispatcher.zip"

}

# Lambda extract_dvf_bronze
resource "aws_lambda_function" "ingestion_to_bronze" {
    filename = data.archive_file.extract_dvf_bronze.output_path
    function_name = "evaluation_ingestion_to_bronze"
    role = aws_iam_role.lambda_service_role.arn
    handler = "extract_dvf_bronze.lambda_handler"
    source_code_hash = data.archive_file.extract_dvf_bronze.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 2048
    
}

# Lambda normalize_bronze_to_silver
resource "aws_lambda_function" "bronze_to_silver" {
    filename = data.archive_file.normalize_bronze_to_silver.output_path
    function_name = "evaluation_bronze_to_silver"
    role = aws_iam_role.lambda_service_role.arn
    handler = "normalize_bronze_to_silver.lambda_handler"
    source_code_hash = data.archive_file.normalize_bronze_to_silver.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 2048

    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]
}

# Lambda for prix_m2_par_ville_annee 
resource "aws_lambda_function" "silver_to_gold_prix_m2_par_ville_annee"{
    filename = data.archive_file.lambda_prix_m2_par_ville_annee.output_path
    function_name = "prix_m2_par_ville_annee"
    role = aws_iam_role.lambda_service_role.arn
    handler = "lambda_prix_m2_par_ville_annee.lambda_handler"
    source_code_hash = data.archive_file.lambda_prix_m2_par_ville_annee.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 512

    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]

}

# Lambda for nombre de biens en fonction de l'année , type et ville 
resource "aws_lambda_function" "silver_to_gold_nombre_de_biens" {
    filename = data.archive_file.lambda_nombre_biens_vendu_par_type_ville_annee.output_path
    function_name = "nombre_de_biens"
    role = aws_iam_role.lambda_service_role.arn
    handler = "lambda_nombre_biens_vendu_par_type_ville_annee.lambda_handler"
    source_code_hash = data.archive_file.lambda_nombre_biens_vendu_par_type_ville_annee.output_base64sha256
    runtime  = "python3.11"
    timeout = 900
    memory_size = 512

    
    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]

}

# Lambda dispatcher pour appeler au des lambda du gold 
resource "aws_lambda_function" "silver_to_gold_dispatcher" {
    filename = data.archive_file.lambda_dispatcher.output_path
    function_name = "dispatcher_to_lambda_gold"
    role = aws_iam_role.lambda_service_role.arn
    handler = "dispatcher.lambda_handler"
    source_code_hash = data.archive_file.lambda_dispatcher.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 512

    
}

# Lambda for sns logging
resource "aws_lambda_function" "sns_logger" {
  filename = data.archive_file.sns_logging.output_path
  function_name = "sns_logger"
  role          = aws_iam_role.lambda_service_role.arn
  handler       = "lambda_logging.lambda_handler"
  source_code_hash = data.archive_file.dlq_alert.output_base64sha256
  runtime       = "python3.11"
  timeout = 900
  memory_size = 512

}



# Lambda for dlq alert 
resource "aws_lambda_function" "lambda_dlq_alert" {
    filename = data.archive_file.dlq_alert.output_path
    function_name = "dlq_alert"
    role = aws_iam_role.lambda_service_role.arn
    handler = "dlq_alert.lambda_handler"
    source_code_hash = data.archive_file.dlq_alert.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 512

    environment {
        variables = {
            SNS_TOPIC_ARN = aws_sns_topic.pipeline_notifications_and_alert_dlq.arn
        }
  }

    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]
}

# Lambda for test
resource "aws_lambda_function" "test_lambda"{
    filename = data.archive_file.test.output_path
    function_name = "test_yes"
    role = aws_iam_role.lambda_service_role.arn
    handler = "test.lambda_handler"
    source_code_hash = data.archive_file.test.output_base64sha256
    runtime = "python3.11"
    timeout = 900
    memory_size = 512

    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]

}



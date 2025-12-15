# Package de la lambda extract_dvf_bronze
data "archive_file" "extract_dvf_bronze" {
    type = "zip"
    source_file = "${path.module}/lambda/extract_dvf_bronze.py"
    output_path = "${path.module}/lambda/extract_dvf_bronze.zip"
}

# Package de la lambda normalize_bronze_to_silver
data "archive_file" "normalize_bronze_to_silver"{
    type = "zip"
    source_file = "${path.module}/lambda/normalize_bronze_to_silver.py"
    output_path = "${path.module}/lambda/normalize_bronze_to_silver.zip"
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
    memory_size = 512
    
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
    memory_size = 512

    layers = [
        aws_lambda_layer_version.pandas_numpy_layer.arn
    ]
}
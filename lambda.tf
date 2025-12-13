# Package de la lambda extract_dvf_bronze
data "archive_file" "extract_dvf_bronze" {
    type = "zip"
    source_file = "${path.module}/lambda/extract_dvf_bronze.py"
    output_path = "${path.module}/lambda/extract_dvf_bronze.zip"
}

# Lambda extract_dvf_bronze
resource "aws_lambda_function" "ingestion_to_bronze" {
    filename = data.archive_file.extract_dvf_bronze.output_path
    function_name = "evaluation_ingestion_to_bronze"
    role = aws_iam_role.lambda_service_role.arn
    handler = "extract_dvf_bronze.lambda_handler"
    source_code_hash = data.archive_file.extract_dvf_bronze.output_base64sha256
    runtime = "python3.11"
    timeout = 300
    memory_size = 512
    
}
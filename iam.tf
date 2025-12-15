# Role for S3 
resource "aws_iam_role" "s3_service_role" {
    name = "evaluation_s3_service_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            # Avoir l'accès au service s3
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = [
                        "s3.amazonaws.com"
                    ]
                }
            } ,
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::000000000000:root" # LocalStack account
                }
                Condition = {
                    StringEquals = {
                        "sts:ExternalId" = "unique-external-id"
                    }
                }
            }
        ]
    })
}

# Role for lambda 
resource "aws_iam_role" "lambda_service_role" {
    name = "evaluation_lambda_service_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            # Avoir l'accès au service s3
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = [
                        "lambda.amazonaws.com"
                    ]
                }
            } ,
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::000000000000:root" # LocalStack account
                }
                Condition = {
                    StringEquals = {
                        "sts:ExternalId" = "unique-external-id"
                    }
                }
            }
        ]
    })
}


# S3 policy 
resource "aws_iam_policy" "s3_policy" {
    name = "evaluation_s3_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject" , "s3:putObjectAcl"
                ]
                Resource = [
                    "${aws_s3_bucket.test_bucket.arn}", 
                    "${aws_s3_bucket.test_bucket.arn}/*"
                ]
            }
        ]
    })
}

# lambda policy 
resource "aws_iam_policy" "lambda_s3" {
    name = "evaluation_lambda_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:PutObject", 
                    "s3:CreateMultipartUpload", 
                    "s3:UploadPart", 
                    "s3:CompleteMultipartUpload", 
                    "s3:AbortMultipartUpload"
                ]
                Resource = [
                    "${aws_s3_bucket.test_bucket.arn}", 
                    "${aws_s3_bucket.test_bucket.arn}/*"
                ]
            }
        ]
    })
}

# log policies
resource "aws_iam_policy" "lambda_logs" {
    name = "evaluation_lambda_logs_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
                ]
                Resource = "arn:aws:logs:*:*:*"
            }
        ]
    })
}

# Attache s3 policies with s3 role 
resource "aws_iam_role_policy_attachment" "s3_managed" {
    role = aws_iam_role.s3_service_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
} 

# Attache lambda policies with lambda role 
resource "aws_iam_role_policy_attachment" "lambda_managed" {
    role = aws_iam_role.lambda_service_role.name
    policy_arn = aws_iam_policy.lambda_s3.arn
}

# Attached logs policies with lambda role 
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambda_service_role.name
    policy_arn = aws_iam_policy.lambda_logs.arn 
}


# Permission lambda for S3 
resource "aws_lambda_permission" "allow_s3" {
    statement_id = "AllowExecutionFromS3"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.bronze_to_silver.arn
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.test_bucket.arn
}

# Déclenchement de la fonction lambda_handler à partir du dossier bronze 
resource "aws_s3_bucket_notification" "bronze_notify"{
    bucket = aws_s3_bucket.test_bucket.id
    
    lambda_function {
        lambda_function_arn = aws_lambda_function.bronze_to_silver.arn
        events = ["s3:ObjectCreated:*"] 
        filter_prefix = "bronze/"
    }

    depends_on = [aws_lambda_permission.allow_s3]
}


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

# Role for CloudWatch
resource "aws_iam_role" "cloudwatch_service_role" {
    name = "evaluation_cloudwatch_service_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = [
                        "events.amazonaws.com"
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
                    "${aws_s3_bucket.bucket_bronze.arn}", 
                    "${aws_s3_bucket.bucket_bronze.arn}/*",
                    "${aws_s3_bucket.bucket_silver.arn}", 
                    "${aws_s3_bucket.bucket_silver.arn}/*",
                    "${aws_s3_bucket.bucket_gold.arn}", 
                    "${aws_s3_bucket.bucket_gold.arn}/*",
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
                    "${aws_s3_bucket.bucket_bronze.arn}", 
                    "${aws_s3_bucket.bucket_bronze.arn}/*",
                    "${aws_s3_bucket.bucket_silver.arn}", 
                    "${aws_s3_bucket.bucket_silver.arn}/*",
                    "${aws_s3_bucket.bucket_gold.arn}", 
                    "${aws_s3_bucket.bucket_gold.arn}/*",
                ]
            } 
        ]
    })
}

# Lambda sns publish policy 
resource "aws_iam_policy" "lambda_sns_publish_policy" {
    name = "lambda-sns-publish-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "sns:Publish"
                ]
                Resource = [
                    aws_sns_topic.pipeline_notifications_and_alert_dlq.arn
                ]
            }
        ]
    })
}

resource "aws_iam_policy" "lambda_invoke" {
    name = "evaluation_lambda_invoke_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "lambda:InvokeFunction"
                Resource = [
                    aws_lambda_function.silver_to_gold_nombre_de_biens.arn ,
                    aws_lambda_function.silver_to_gold_prix_m2_par_ville_annee.arn
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

# cloudwatch policies 
resource "aws_iam_policy" "cloudwatch_policy" {
    name = "evaluation_cloudwatch_policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "cloudwatch:PutMetricData"
                ]
                Resource = "*"
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

# Attached cloudwatch policies with cloudwatch role 
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach"{
    role = aws_iam_role.lambda_service_role.name
    policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# Attached lambda invoke policy with lambda role 
resource "aws_iam_role_policy_attachment" "lambda_invoke" {
    role = aws_iam_role.lambda_service_role.name
    policy_arn = aws_iam_policy.lambda_invoke.arn
}

# Attachement lambda to sns 
resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
    role = aws_iam_role.lambda_service_role.name
    policy_arn = aws_iam_policy.lambda_sns_publish_policy.arn
}

# Permission a sns pour appelle a une fonction lambda
resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_logger.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.pipeline_notifications_and_alert_dlq.arn

}


# Permission lambda for S3 
resource "aws_lambda_permission" "allow_s3" {
    statement_id = "AllowExecutionFromS3"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.bronze_to_silver.arn
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.bucket_bronze.arn
}



# Allow s3 to send message
resource "aws_sqs_queue_policy" "allow_s3_to_send" {
  queue_url = aws_sqs_queue.silver_to_gold_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.silver_to_gold_queue.arn
      }
    ]
  })
}



# Notifications pour le bucket Bronze
resource "aws_s3_bucket_notification" "bronze_notifications" {
  bucket = aws_s3_bucket.bucket_bronze.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.bronze_to_silver.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "bronze/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}

# Notifications pour le bucket Silver
resource "aws_s3_bucket_notification" "silver_notifications" {
  bucket = aws_s3_bucket.bucket_silver.id

  queue {
    queue_arn     = aws_sqs_queue.silver_to_gold_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "silver/"
  }

  depends_on = [
    aws_sqs_queue_policy.allow_s3_to_send
  ]
}




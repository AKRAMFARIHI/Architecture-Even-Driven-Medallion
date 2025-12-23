resource "aws_sqs_queue" "silver_to_gold_queue" {
    name = "evaluation-silver-to-gold-queue"
    message_retention_seconds = 1209600

    redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.lambda_dlq.arn
        maxReceiveCount = 3
    })

    tags = {
        Purpose = "Silver to Gold processing"
    }
}

resource "aws_sqs_queue" "lambda_dlq" {
    name = "evaluation-dlq"
    message_retention_seconds = 1209600

    tags = {
        Purpose = "DLQ for silver to Gold dlq"
    }
}
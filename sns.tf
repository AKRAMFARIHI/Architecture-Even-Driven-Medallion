resource "aws_sns_topic" "pipeline_notifications_and_alert_dlq" {
    name = "evaluation-pipeline-notifications-and-alert-dlq"
}

resource "aws_sns_topic_subscription" "sns_logger_subscription" {
  topic_arn = aws_sns_topic.pipeline_notifications_and_alert_dlq.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_logger.arn
}

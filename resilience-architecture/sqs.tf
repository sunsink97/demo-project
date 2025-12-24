resource "aws_sqs_queue" "counter_dlq" {
  name = "${var.env}-${var.project_name}-counter-dlq"

  message_retention_seconds = 345600 // set to 4 days

  tags = local.common_tags
}

resource "aws_sqs_queue" "counter_queue" {
  name = "${var.env}-${var.project_name}-counter-queue"

  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.counter_dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_consume_counter_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [aws_sqs_queue.counter_queue.arn]
  }
}

resource "aws_iam_policy" "lambda_consume_counter_queue" {
  name   = "${var.env}-${var.project_name}-lambda-consume-counter-queue"
  policy = data.aws_iam_policy_document.lambda_consume_counter_queue.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_consume_counter_queue" {
  role       = module.resilience_lambda.lambda_role_name
  policy_arn = aws_iam_policy.lambda_consume_counter_queue.arn
}

resource "aws_lambda_event_source_mapping" "counter_queue_to_lambda" {
  event_source_arn = aws_sqs_queue.counter_queue.arn
  function_name    = module.resilience_lambda.lambda_arn

  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
}
resource "aws_iam_role" "resilience_lambda_role" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "resilience_lambda_role_attachment" {
  role       = aws_iam_role.resilience_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.resilience_lambda_role.arn

  handler = var.handler
  runtime = var.runtime

  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = ["x86_64"]

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}
locals {
  common_tags = {
    project          = var.project_name
    env              = var.env
    managedby        = "Terraform"
    MaintenanceWindw = "SUN_17"
    Backup-plan      = "default"
    ProductCOde      = "RA_demo"
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-demo-resilience-architecture"
    key            = "resilience-architecture/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-resilience-lock"
    encrypt        = true
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "s3_ra_architecture" {
  source               = "./module/s3-module"
  bucket_name          = "${var.env}-resilience-architecture-${random_id.suffix.hex}"
  enable_s3_versioning = true
  block_public_access  = true
}

//rule for lambda for dynamo
data "aws_iam_policy_document" "lambda_dynamodb_counter" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.lambda_invocation_counter.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_counter" {
  name   = "${var.env}-${var.project_name}-lambda-dynamodb-counter"
  policy = data.aws_iam_policy_document.lambda_dynamodb_counter.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_counter_attach" {
  role       = module.resilience_lambda.lambda_role_name
  policy_arn = aws_iam_policy.lambda_dynamodb_counter.arn
}

data "archive_file" "resilience_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/resilience_function.py"
  output_path = "${path.module}/lambda/resilience_lambda.zip"
}

module "resilience_lambda" {
  source   = "./module/lambda-module"
  name     = "${var.env}-resilience-architecture-lambda"
  filename = data.archive_file.resilience_lambda_zip.output_path
  handler  = "resilience_function.lambda_handler"
  runtime  = var.lambda_version

  environment_variables = {
    test_env_var       = "something something env var"
    COUNTER_TABLE_NAME = aws_dynamodb_table.lambda_invocation_counter.name
  }

  tags = local.common_tags
}

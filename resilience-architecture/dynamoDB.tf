resource "aws_dynamodb_table" "lambda_invocation_counter" {
  name         = "${var.env}-${var.project_name}-lambda-counter"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "partition_key"

  attribute {
    name = "partition_key"
    type = "string"
  }

  point_in_time_recovery {
    enabled = true
  }
  tags = local.common_tags
}
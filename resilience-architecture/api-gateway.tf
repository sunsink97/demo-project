data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
resource "aws_iam_role" "apigw_send_counter_queue" {
  name = "${var.env}-${var.project_name}-apigw-send-counter-queue"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "apigw_send_counter_queue" {
  name = "${var.env}-${var.project_name}-apigw-send-counter-queue"
  role = aws_iam_role.apigw_send_counter_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:SendMessage"],
      Resource = aws_sqs_queue.counter_queue.arn
    }]
  })
}

resource "aws_api_gateway_rest_api" "counter_api" {
  name        = "${var.env}-${var.project_name}-counter-api"
  description = "REST API -> SQS counter_queue"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

resource "aws_api_gateway_resource" "counter" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  parent_id   = aws_api_gateway_rest_api.counter_api.root_resource_id
  path_part   = "counter"
}

resource "aws_api_gateway_method" "counter_post" {
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "counter_post_sqs" {
  rest_api_id             = aws_api_gateway_rest_api.counter_api.id
  resource_id             = aws_api_gateway_resource.counter.id
  http_method             = aws_api_gateway_method.counter_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apigw_send_counter_queue.arn

  uri = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.counter_queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
    "text/plain"       = "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
  }
}

resource "aws_api_gateway_method_response" "counter_post_200" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "counter_post_200" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_post.http_method
  status_code = aws_api_gateway_method_response.counter_post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [aws_api_gateway_integration.counter_post_sqs]
}

resource "aws_api_gateway_method" "counter_options" {
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "counter_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "counter_options_200" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "counter_options_200" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = aws_api_gateway_method_response.counter_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  depends_on = [aws_api_gateway_integration.counter_options_mock]
}


resource "aws_api_gateway_deployment" "counter_deploy" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id

  //  redeploy on changes
  triggers = {
    redeploy = sha1(jsonencode({
      post_method         = aws_api_gateway_method.counter_post.id
      post_integration    = aws_api_gateway_integration.counter_post_sqs.id
      options_method      = aws_api_gateway_method.counter_options.id
      options_integration = aws_api_gateway_integration.counter_options_mock.id
    }))
  }

  depends_on = [
    aws_api_gateway_integration_response.counter_post_200,
    aws_api_gateway_integration_response.counter_options_200
  ]
}

resource "aws_api_gateway_stage" "counter_stage" {
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  deployment_id = aws_api_gateway_deployment.counter_deploy.id
  stage_name    = var.env

  tags = local.common_tags
}

output "counter_enqueue_url" {
  value = "${aws_api_gateway_stage.counter_stage.invoke_url}/counter"
}

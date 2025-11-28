resource "aws_apigatewayv2_api" "microservice_chat_bot_api" {
  name          = "chat-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # or ["https://your-cloudfront-domain"]
    allow_methods = ["OPTIONS", "POST"]
    allow_headers = ["content-type"]
  }
}

# Integrate Lambda → API
resource "aws_apigatewayv2_integration" "microservice_chat_bot_integration" {
  api_id                 = aws_apigatewayv2_api.microservice_chat_bot_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.microservice_chat_bot_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Create /chat route
resource "aws_apigatewayv2_route" "chat_route" {
  api_id    = aws_apigatewayv2_api.microservice_chat_bot_api.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.microservice_chat_bot_integration.id}"
}


# Stage for public URL
resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.microservice_chat_bot_api.id
  name        = "dev"
  auto_deploy = true
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_invoke" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.microservice_chat_bot_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.microservice_chat_bot_api.execution_arn}/*/*"
}
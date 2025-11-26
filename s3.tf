resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "microservice_chat_bot" {
  bucket = "${var.environment}-microservice-chat-bot-${random_id.suffix.hex}"

  tags = {
    Name        = "demo bucket"
    Environment = "${var.environment}"
    description = "S3 Bucket for website hosting"
  }
}

resource "aws_s3_bucket_website_configuration" "microservice_chat_bot_hosting_configuration" {
  bucket = aws_s3_bucket.microservice_chat_bot.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy_microservice_chat_bot" {
  bucket = aws_s3_bucket.microservice_chat_bot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.microservice_chat_bot.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.microservice_chat_bot_s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "microservice_chat_bot_index" {
  bucket = aws_s3_bucket.microservice_chat_bot.id
  key    = "index.html"

  source = "${path.module}/Files/index.html"

  content_type = "text/html"
}
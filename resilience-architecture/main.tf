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

module "resilience_lambda" {
  source   = "./module/lambda-module"
  name     = "${var.env}-resilience-architecture-lambda"
  filename = "module/lambda-module/lambda.zip"
  handler  = "lambda_function.lambda_handler"
  runtime  = var.lambda_version

  environment_variables = {
    test_api     = "super secret api"
    test_env_var = "something"
  }

  tags = local.common_tags
}

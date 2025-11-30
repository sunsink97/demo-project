variable "environment" {
  default = "dev"
  type    = string
}

variable "python_version" {

  default = "python3.12"
  type    = string
}

variable "project_name" {

  default = "microservice-architecture"
  type    = string
}

variable "groq_api" {
  type      = string
  sensitive = true
}

variable "lambda_initial_spec" {
  type = object({
    memory_size      = number
    timeout          = number
    ephemeral_storage = object({
      size = number
    })
  })

  default = {
    memory_size      = 512
    timeout          = 10
    ephemeral_storage = {
      size = 512
    }
  }
}
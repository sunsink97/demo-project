variable "name" {
  description = "Lambda function name"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Handler format index.handler"
  type        = string
  default     = "index.handler"
}

variable "filename" {
  description = "Path to zipped Lambda code"
  type        = string
}

variable "memory_size" {
  description = "Lambda memory size (MB)"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Module-specific tags"
}

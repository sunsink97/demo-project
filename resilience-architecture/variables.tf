variable "env" {
  default     = "dev"
  type        = string
  description = "variable"
}

variable "project_name" {
  description = "project name"
  type        = string
  default     = "resilience architecture"
}

variable "lambda_version" {
  default = "python3.12"
  type    = string
}

//VPC
variable "vpc_cidr" {
  type        = string
  description = "Base VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "az_map" {
  description = "Map of AZ keys to availability zones"
  type        = map(string)
  default = {
    az1 = "ap-southeast-1a"
    az2 = "ap-southeast-1b"
  }
}

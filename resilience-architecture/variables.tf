variable "env" {
  default     = "dev"
  type        = string
  description = "variable"
}

variable "project_name" {
  description = "project name"
  type        = string
  default     = "resilience-architecture"
}

variable "lambda_version" {
  default = "python3.12"
  type    = string
}

//VPC variables
variable "vpc_cidr" {
  type        = string
  description = "Base VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Map of AZ keys to availability zones"
  type        = map(string)
  default = {
    az1 = "ap-southeast-1a"
    az2 = "ap-southeast-1b"
  }
}

variable "golden_ami_id" {
  type        = string
  description = "golden ami id"
  default     = "ami-093a7f5fbae13ff67"
}

variable "golden_ami_spec" {
  description = "ami spec"
  type = object({
    id               = string
    instance_type    = string
    architecture     = string
    virtualization   = string
    root_device_type = string
    description      = string
  })

  default = {
    id               = "ami-0b8b20b0a6f3ad5c6"
    instance_type    = "t3.micro"
    architecture     = "x86_64"
    virtualization   = "hvm"
    root_device_type = "ebs"
    description      = "Amazon Linux 2, HVM, 64-bit, EBS-backed (baseline golden AMI)"
  }
}

//asg var
variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "resilience-app-asg"
}

variable "asg_max_size" {
  description = "Maximum number of instances for the ASG"
  type        = number
  default     = 1
}

variable "asg_min_size" {
  description = "Minimum number of instances for the ASG"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of instances for the ASG"
  type        = number
  default     = 1
}

variable "asg_health_check_grace_period" {
  description = "Grace period in seconds for ASG health checks"
  type        = number
  default     = 300
}
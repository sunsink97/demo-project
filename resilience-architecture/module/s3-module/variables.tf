variable "bucket_name" {
  description = "bucket name."
  type        = string
}

variable "block_public_access" {
  description = "block public access"
  type        = bool
  default     = true
}

variable "enable_s3_versioning" {
  description = "enabling versioning for s3 bucket or not"
  type        = bool
  default     = true
}
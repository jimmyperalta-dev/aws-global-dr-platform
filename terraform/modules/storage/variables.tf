# terraform/modules/storage/variables.tf

variable "environment" {
  description = "Environment name (primary or dr)"
  type        = string
  validation {
    condition     = can(regex("^(primary|dr)$", var.environment))
    error_message = "Environment must be either 'primary' or 'dr'."
  }
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "destination_bucket_arn" {
  description = "ARN of the destination bucket for cross-region replication"
  type        = string
  default     = ""
}

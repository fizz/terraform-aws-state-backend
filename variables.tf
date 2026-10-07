variable "name" {
  description = "Name of the state bucket. Bucket names are global, so include the account id or an organization prefix."
  type        = string
}

variable "kms_alias" {
  description = "Alias for the state key, with the alias/ prefix. Defaults to alias/<name>."
  type        = string
  default     = null
}

variable "kms_deletion_window_days" {
  description = "Days a scheduled key deletion waits. Everything in the bucket is unreadable without the key, so keep this at the maximum."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS accepts 7 to 30 days."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days an overwritten state version is kept. Versions are the undo for a bad apply, so this is your rollback window."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Let terraform destroy delete a bucket that still holds state. Leave false."
  type        = bool
  default     = false
}

output "bucket" {
  description = "Name of the state bucket."
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "ARN of the state bucket, for the policy that lets a role read and write state."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the state key. A role that reads state needs kms:Decrypt on it, and one that writes needs kms:GenerateDataKey."
  value       = aws_kms_key.state.arn
}

output "kms_alias" {
  description = "Alias of the state key."
  value       = aws_kms_alias.state.name
}

output "backend_config" {
  description = "A backend block for a root to use this bucket, with key left to the caller. Paste it into the root once the bucket exists."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.state.bucket}"
        key          = "CHANGE_ME/terraform.tfstate"
        region       = "${aws_s3_bucket.state.region}"
        encrypt      = true
        use_lockfile = true
        kms_key_id   = "${aws_kms_alias.state.name}"
      }
    }
  EOT
}

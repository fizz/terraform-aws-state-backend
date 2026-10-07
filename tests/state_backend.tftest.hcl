# Plan-level checks with a mocked provider: no credentials, no account.

mock_provider "aws" {}

variables {
  name = "acme-tfstate-111122223333"
}

run "bucket_is_versioned_and_private" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning is the undo for a bad apply and must be on."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.state.block_public_acls,
      aws_s3_bucket_public_access_block.state.block_public_policy,
      aws_s3_bucket_public_access_block.state.ignore_public_acls,
      aws_s3_bucket_public_access_block.state.restrict_public_buckets,
    ])
    error_message = "All four public access blocks must be on."
  }

  assert {
    condition     = aws_s3_bucket.state.force_destroy == false
    error_message = "A bucket holding state must not be force-destroyable by default."
  }
}

run "state_is_encrypted_with_a_rotating_key" {
  command = plan

  assert {
    condition     = aws_kms_key.state.enable_key_rotation
    error_message = "The state key must rotate."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "State must be encrypted with KMS, not the S3 default."
  }
}

# The policy embeds the bucket ARN, which is unknown until apply, so this run applies
# against the mock.
run "plain_http_is_denied" {
  command = apply

  assert {
    condition     = strcontains(aws_s3_bucket_policy.tls_only.policy, "aws:SecureTransport")
    error_message = "The bucket policy must deny requests that are not TLS."
  }
}

run "alias_defaults_to_the_bucket_name" {
  command = plan

  assert {
    condition     = aws_kms_alias.state.name == "alias/acme-tfstate-111122223333"
    error_message = "The alias should default to alias/<name>."
  }
}

run "alias_can_be_overridden" {
  command = plan

  variables {
    kms_alias = "alias/team-state"
  }

  assert {
    condition     = aws_kms_alias.state.name == "alias/team-state"
    error_message = "An explicit alias must win."
  }
}

run "old_versions_expire" {
  command = plan

  variables {
    noncurrent_version_expiration_days = 30
  }

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.state.rule).noncurrent_version_expiration[0].noncurrent_days == 30
    error_message = "The rollback window must follow the variable."
  }
}

run "key_deletion_window_is_bounded" {
  command = plan

  variables {
    kms_deletion_window_days = 3
  }

  expect_failures = [var.kms_deletion_window_days]
}

# terraform-aws-state-backend

Remote state for one Terraform root on AWS: a KMS-encrypted, versioned, private S3
bucket that refuses plain HTTP, plus the key that encrypts it. Locking uses the S3
lockfile (`use_lockfile`), so there is no DynamoDB table.

```hcl
module "state" {
  source = "fizz/state-backend/aws"

  name = "acme-tfstate-${data.aws_caller_identity.current.account_id}"
}

output "backend_config" {
  value = module.state.backend_config
}
```

| Resource | What it is for |
|---|---|
| `aws_s3_bucket` | Holds state. Versioned, all four public access blocks on. |
| `aws_kms_key` and alias | Customer-managed key with rotation, 30 day deletion window. |
| `aws_s3_bucket_policy` | Denies any request that is not TLS. |
| `aws_s3_bucket_lifecycle_configuration` | Expires overwritten versions after 90 days. |

Requires Terraform 1.10 or later in the roots that use the bucket (`use_lockfile`).
The module itself needs 1.7.

## The bootstrap problem

The bucket that holds state has to exist before state can live in it. The module
cannot create its own backend, so the first apply uses local state and then moves:

1. Declare the module in a root with no `backend` block. Run `terraform apply`. State
   is written to `terraform.tfstate` on disk.
2. Read the `backend_config` output and paste it into the root as `backend.tf`.
3. Run `terraform init -migrate-state` and answer `yes`. Terraform copies the local
   state into the bucket.
4. Check that the bucket now holds the object, then delete the local
   `terraform.tfstate` and its `.backup`.

The same root now manages the bucket that stores its own state. That is fine, and
`terraform destroy` on it is the one command you must never run casually. Put
`prevent_destroy` on the module call's surrounding resources, or keep the state
bucket in a root of its own.

## What is hard to get right

**The key outlives everything.** Every version of every state file is unreadable
without the KMS key. Scheduling its deletion starts a clock, and the shortest window
is 7 days. The module defaults to 30 and the alias is what roots reference, so a key
rotation by replacement does not need every backend block edited.

**Access needs two grants, not one.** A role that reads state needs `s3:GetObject` on
the bucket and `kms:Decrypt` on the key. One that writes needs `s3:PutObject` and
`kms:GenerateDataKey`. Granting only the S3 half fails with an error that mentions
neither. The `bucket_arn` and `kms_key_arn` outputs exist for those policies.

**Versions pile up.** Versioning is the undo for a bad apply, and it keeps every
overwritten state forever. The lifecycle rule expires noncurrent versions after
`noncurrent_version_expiration_days`. Treat that number as your rollback window.

**The policy and the public access block race.** Both write the bucket policy, and
applying them in parallel fails intermittently. The policy depends on the block.

**`force_destroy` stays false.** With it on, a destroy deletes a bucket full of state
without asking.

## Inputs and outputs

See `variables.tf` and `outputs.tf`. Every one is documented, and CI fails if one is
not.

## Tests

`terraform test` runs against a mocked AWS provider with no credentials. CI also
validates against the oldest and newest provider majors the module supports.

## License

MIT.

resource "aws_s3_bucket" "bucket_backend" {
  #checkov:skip=CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
  #checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  #checkov:skip=CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
  #checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  bucket = var.bucket_backend_name

  tags = {
    "Name" = "S3 Remote Terraform State Store"
  }
}

resource "aws_s3_bucket_versioning" "bucket_backend" {
  bucket = aws_s3_bucket.bucket_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_backend" {
  bucket = aws_s3_bucket.bucket_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_backend" {
  bucket                  = aws_s3_bucket.bucket_backend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_kms_key" "terraform_kms_key" {
  description         = "Terraform KMS Key"
  enable_key_rotation = true

  tags = {
    "Name" = "KMS key to encrypt Terraform State Lock Table"
  }
}

resource "aws_dynamodb_table" "terraform-lock" {
  #checkov:skip=CKV2_AWS_16: "Ensure that Auto Scaling is enabled on your DynamoDB tables"
  name           = "terraform_state"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_kms_key.arn
  }

  tags = {
    "Name" = "DynamoDB Terraform State Lock Table"
  }
}

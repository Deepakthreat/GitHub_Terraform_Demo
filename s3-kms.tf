terraform {
  required_version = ">= 1.00"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "automation"

}
resource "aws_kms_key" "key" {
  description             = var.kms_key_description
  tags                    = var.tags
  deletion_window_in_days = var.kms_deletion_window_in_days
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/${lower(var.kms_key_alias)}"
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket

  force_destroy = true
  tags          = var.tags

}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    id = "rule-1-logs"

    filter {
      prefix = "logs/"
    }
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_policy" "demo-policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "Policy1357935677554",
    "Statement": [
        {
            "Sid": "Stmt1357935647218",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.current.arn}"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${var.s3_bucket}"
        },
        {
            "Sid": "Stmt1357935676138",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.current.arn}"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${var.s3_bucket}/*"
        }
    ]
}
POLICY
}
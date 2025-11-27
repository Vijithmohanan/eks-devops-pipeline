provider "aws" {
  region = "us-east-1" # Your desired region
}

# S3 Bucket for state storage (must be globally unique)
resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "hollslane-tfstate-2025" 
  acl    = "private"
  versioning {
    enabled = true
  }
}

# DynamoDB Table for state locking (prevents concurrent applies)
resource "aws_dynamodb_table" "tf_state_lock" {
  name           = "terraform-state-lock-ddb"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.tf_state_bucket.id
}

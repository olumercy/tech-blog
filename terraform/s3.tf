# Creates an S3 bucket named "terraform-olumercy-bucket" with a tag specifying that it belongs to the development environment
resource "aws_s3_bucket" "cloud_talent_blog" {
    bucket = "terraform-olumercy-bucket"
    force_destroy = true
    tags = {
        environment = "dev"
  }
}

# Configures the S3 bucket as a static website, setting "index.html" as the default document
resource "aws_s3_bucket_website_configuration" "cloud_talent_blog" {
  bucket = aws_s3_bucket.cloud_talent_blog.id

  index_document {
    suffix = "index.html"
  }
}

# Defines public access settings for the bucket, overriding default security settings
resource "aws_s3_bucket_public_access_block" "cloud_talent_blog" {
  bucket = aws_s3_bucket.cloud_talent_blog.id

  # Allows public ACLs and policies while ignoring individual public ACL settings
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Enables versioning on the bucket to keep track of changes and modifications to objects
resource "aws_s3_bucket_versioning" "cloud_talent_blog" {
      bucket = aws_s3_bucket.cloud_talent_blog.bucket
    versioning_configuration {
        status = "Enabled"
    }
}

# Defines a bucket policy that allows public read access to objects in the bucket
resource "aws_s3_bucket_policy" "cloud_talent_blog1" {
  bucket = aws_s3_bucket.cloud_talent_blog.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"  # Allows any user to access objects in the bucket
        Action    = "s3:GetObject"  # Grants permission to retrieve objects
        Resource  = "${aws_s3_bucket.cloud_talent_blog.arn}/*" # Applies policy to all objects in the bucket
      }
    ]
  })
}


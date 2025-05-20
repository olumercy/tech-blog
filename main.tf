//S3_bucket config starts here
# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
 assume_role {
    role_arn = "arn:aws:iam::457087769557:role/Terraformoidc-role"
  }
}




# Creates an S3 bucket named "terraform-olumercy-bucket" with a tag specifying that it belongs to the development environment
resource "aws_s3_bucket" "cloud_talent_blog" {
    bucket = "terraform-olumercy-bucket"
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



//cloudnfront Starts
# Define an origin access control policy for CloudFront to securely access the S3 bucket.
resource "aws_cloudfront_origin_access_control" "webblog_access" {
    name = "cloud_talent_CDN_access"
    origin_access_control_origin_type = "s3"  # Specifies that CloudFront is accessing an S3 bucket.
    signing_behavior = "always"  # Ensures all requests are signed for authentication.
    signing_protocol = "sigv4"  # Uses Signature Version 4, a secure signing method.
}

# Configure the CloudFront distribution
resource "aws_cloudfront_distribution" "cloud_talent_CDN" {

    depends_on = [ 
        aws_s3_bucket.cloud_talent_blog,  # Ensures the S3 bucket exists before creating CloudFront.
        aws_cloudfront_origin_access_control.webblog_access  # Ensures the origin access control is set.
    ]

    enabled = true  # Activates the CloudFront distribution.
    default_root_object = "index.html"  # The default file served when accessing the domain.

    # Define cache behavior for the CDN
    default_cache_behavior {
      allowed_methods = [ "GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]  # Restricts methods to GET and HEAD.
      cached_methods = [ "GET", "HEAD" ]  # Only caches GET and HEAD requests.
      target_origin_id = aws_s3_bucket.cloud_talent_blog.id  # Associates this behavior with the S3 bucket.
      viewer_protocol_policy = "https-only"  # Enforces HTTPS for secure communication.

      # Control forwarded request parameters
      forwarded_values {
          query_string = false  # Does not forward query strings, improving cache efficiency.
          cookies {
              forward = "none"  # Prevents forwarding cookies to the origin.
          }
      }
    }

    # Define the origin configuration
    origin {
        domain_name = aws_s3_bucket.cloud_talent_blog.bucket_domain_name  # Uses the S3 bucket's domain name.
        origin_id = aws_s3_bucket.cloud_talent_blog.id  # Identifies the origin.
        origin_access_control_id = aws_cloudfront_origin_access_control.webblog_access.id  # Applies the access control.
    }

    # No geo-restrictions on access
    restrictions {
        geo_restriction {
            restriction_type = "none"  # Allows access from all geographic locations.
        }
    }

    # Uses CloudFront’s default certificate for HTTPS
    viewer_certificate {
        cloudfront_default_certificate = true  # Enables HTTPS using a default CloudFront certificate.
    }
}
# Define an IAM policy document to permit CloudFront access
data "aws_iam_policy_document" "cloud_talent_blog" {
    depends_on = [ 
        aws_cloudfront_distribution.cloud_talent_CDN,  # Ensures CloudFront distribution is created first.
        aws_s3_bucket.cloud_talent_blog  # Ensures the S3 bucket is available.
    ]
    
    statement {
        sid = "3"
        effect = "Allow"
        actions = [ "s3:GetObject", 
                    "s3:PutObject",  # Allows uploading objects to S3
                    "s3:ListBucket",  # Allows listing objects in the S3 bucket
                    "s3:DeleteObject",  # Allows deleting objects from S3
                    "cloudfront:CreateInvalidation"  # Allows invalidating cached CloudFront objects
                    
        ]  # Grants permission to read objects from S3.

        principals {
            identifiers = ["cloudfront.amazonaws.com"]  # Allows CloudFront as a principal.
            type = "Service"
        }

        resources = [
            "arn:aws:s3:::${aws_s3_bucket.cloud_talent_blog}/*"  # Specifies all objects in the bucket.
        ]

        condition {
            test = "StringEquals"
            variable = "AWS:SourceArn"
            values = [aws_cloudfront_distribution.cloud_talent_CDN.id]  # Restricts access to this CloudFront distribution.
        }
    }
}

# Define an S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cloud_talent_blog" {
    depends_on = [ 
        data.aws_iam_policy_document.cloud_talent_blog  # Ensures the IAM policy document is created first.
    ]
    bucket = aws_s3_bucket.cloud_talent_blog.id  # Specifies the S3 bucket.
    policy = data.aws_iam_policy_document.cloud_talent_blog  # Uses an IAM policy document.
}


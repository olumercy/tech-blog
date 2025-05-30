# Define an origin access control policy for CloudFront to securely access the S3 bucket.
resource "aws_cloudfront_origin_access_control" "webblog_access" {
    name = "cloud_talent_CDN_access"
    origin_access_control_origin_type = "s3"  # Specifies that CloudFront is accessing an S3 bucket.
    signing_behavior = "always"  # Ensures all requests are signed for authentication.
    signing_protocol = "sigv4"  # Uses Signature Version 4, a secure signing method.
}

#Add a CloudFront Function that appends index.html to requests missing a file name
resource "aws_cloudfront_function" "add_index_html" {
  name    = "AddIndexHtmlFunction"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOF
  function handler(event) {
    var request = event.request;

    if (request.uri.includes('.') || request.uri.endsWith('/')) {
      request.uri += '/index.html';
    }

    return request;
  }
  EOF
}


# Configure the CloudFront distribution for serving content securely and efficiently.
resource "aws_cloudfront_distribution" "cloud_talent_CDN" {

    depends_on = [ 
        aws_s3_bucket.cloud_talent_blog,  # Ensures the S3 bucket exists before creating CloudFront.
        aws_cloudfront_origin_access_control.webblog_access  # Ensures the origin access control is set.
    ]

    enabled = true  # Activates the CloudFront distribution.
    default_root_object = "index.html"  # The default file served when accessing the domain.

    # Define cache behavior for the CDN to optimize content delivery.
    default_cache_behavior {
      allowed_methods = [ "GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]  # The list includes all HTTP methods; consider limiting it to GET and HEAD for better security.
      cached_methods = [ "GET", "HEAD" ]  # Only caches GET and HEAD requests for efficiency.
      target_origin_id = aws_s3_bucket.cloud_talent_blog.id  # Associates this behavior with the S3 bucket.
      viewer_protocol_policy = "https-only"  # Enforces HTTPS for secure communication.

      # Add the function association
      function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.add_index_html.arn
    }

      # Control forwarded request parameters to minimize unnecessary requests.
      forwarded_values {
          query_string = false  # Does not forward query strings, improving cache efficiency.
          cookies {
              forward = "none"  # Prevents forwarding cookies to the origin, enhancing cache behavior.
          }
      }
    }

    # Define the origin configuration specifying how CloudFront accesses the S3 bucket.
    origin {
        domain_name = aws_s3_bucket.cloud_talent_blog.bucket_domain_name  # Uses the S3 bucket's domain name.
        origin_id = aws_s3_bucket.cloud_talent_blog.id  # Identifies the origin uniquely.
        origin_access_control_id = aws_cloudfront_origin_access_control.webblog_access.id  # Applies the access control policy.
    }

    # No geo-restrictions, allowing content to be accessible from any location.
    restrictions {
        geo_restriction {
            restriction_type = "none"  # Allows global access without restrictions.
        }
    }

    # Uses CloudFront’s default certificate for HTTPS; consider using a custom certificate for production.
    viewer_certificate {
        cloudfront_default_certificate = true  # Enables HTTPS using a default CloudFront certificate.
    }
}

# Define an S3 bucket policy to allow CloudFront access securely.
resource "aws_s3_bucket_policy" "cloud_talent_blog" {
    depends_on = [ 
        data.aws_iam_policy_document.cloud_talent_blog  # Ensures the IAM policy document is created first.
    ]
    bucket = aws_s3_bucket.cloud_talent_blog.id  # Specifies the S3 bucket.
    policy = data.aws_iam_policy_document.cloud_talent_blog.json  # Uses an IAM policy document to grant permissions.
}

# Define an IAM policy document to explicitly allow CloudFront access to the S3 bucket.
data "aws_iam_policy_document" "cloud_talent_blog" {
    depends_on = [ 
        aws_cloudfront_distribution.cloud_talent_CDN,  # Ensures CloudFront distribution is created first.
        aws_s3_bucket.cloud_talent_blog  # Ensures the S3 bucket is available before applying policies.
    ]
    
    statement {
        sid = "AllowCloudFrontAccess"
        effect = "Allow"

        # Grants permission to read objects from S3.
        principals {
            identifiers = ["cloudfront.amazonaws.com"]  # Allows CloudFront as a principal.
            type = "Service"
        }

        actions = ["s3:GetObject"]  # Grants read-only access to objects in the bucket.

        resources = [
            "arn:aws:s3:::${aws_s3_bucket.cloud_talent_blog.bucket}/*"  # Specifies all objects in the bucket as accessible resources.
        ]

        # Restricts access to only requests originating from the specified CloudFront distribution.
        condition {
            test = "StringEquals"
            variable = "AWS:SourceArn" 
            values = [
                "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cloud_talent_CDN.id}"
            ]
        }
    }
}
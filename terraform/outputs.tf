output "s3_bucket" {
  value = aws_s3_bucket.cloud_talent_blog.id
}
output "cloudFront_ID" {
  value = aws_cloudfront_distribution.cloud_talent_CDN.id
}
output "cloudFront_domain_name" {
  value = aws_cloudfront_distribution.cloud_talent_CDN.domain_name
}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
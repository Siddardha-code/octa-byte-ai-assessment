output "bucket_name" {
  value = aws_s3_bucket.static_site.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.static_site.arn
}

output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "App will be live at this URL after deploy"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.main.id
  description = "Needed in CI/CD to invalidate cache after deploy"
}
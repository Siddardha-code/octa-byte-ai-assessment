output "cloudfront_url" {
  value       = module.storage.cloudfront_domain
  description = "Your app is live at this URL"
}

output "s3_bucket_name" {
  value       = module.storage.bucket_name
  description = "Upload your app files here"
}

output "cloudfront_distribution_id" {
  value       = module.storage.cloudfront_distribution_id
  description = "Used in CI/CD to invalidate cache"
}

output "db_endpoint" {
  value     = module.database.db_endpoint
  sensitive = true
}
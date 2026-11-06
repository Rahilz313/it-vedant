output "cloudfront_url" {
  description = "HTTPS URL for the static site."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "Distribution ID used to create cache invalidations."
  value       = aws_cloudfront_distribution.site.id
}

output "site_bucket_name" {
  description = "Private S3 bucket name for the site."
  value       = aws_s3_bucket.site.id
}

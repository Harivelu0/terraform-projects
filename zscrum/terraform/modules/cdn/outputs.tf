output "website_bucket_name" {
  value = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.website.domain_name
}
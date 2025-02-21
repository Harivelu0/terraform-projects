# ./modules/cdn/main.tf
resource "aws_cloudfront_distribution" "web_app" {
  enabled             = true
  is_ipv6_enabled    = true
  price_class         = "PriceClass_100"
  http_version       = "http2"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ELB-${var.alb_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ELB-${var.alb_name}"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.app_name}-cf-distribution-${var.environment}"
    Environment = var.environment
  }
}
# S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "phil_website" {
  bucket = "phil-roninware-net-${random_string.website_suffix.result}"
}

resource "random_string" "website_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Configure bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "phil_website" {
  bucket = aws_s3_bucket.phil_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Make bucket public for website hosting
resource "aws_s3_bucket_public_access_block" "phil_website" {
  bucket = aws_s3_bucket.phil_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "phil_website" {
  bucket = aws_s3_bucket.phil_website.id
  depends_on = [aws_s3_bucket_public_access_block.phil_website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.phil_website.arn}/*"
      }
    ]
  })
}

# Output the website URL
output "website_url" {
  description = "URL of the static website"
  value       = "http://${aws_s3_bucket_website_configuration.phil_website.website_endpoint}"
}

output "website_bucket_name" {
  description = "Name of the website S3 bucket"
  value       = aws_s3_bucket.phil_website.bucket
}

# Route 53 record for phil.roninware.net
data "aws_route53_zone" "roninware" {
  name         = "roninware.net"
  private_zone = false
}

resource "aws_route53_record" "phil" {
  zone_id = data.aws_route53_zone.roninware.zone_id
  name    = "phil.roninware.net"
  type    = "CNAME"
  ttl     = 300
  records = [aws_s3_bucket_website_configuration.phil_website.website_endpoint]
}
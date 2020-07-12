resource "aws_s3_bucket" "static_bucket" {
  acl    = "public-read"
  force_destroy = true
  tags = {
    Project = "MythicalMysfits"
  }

  website {
    index_document = "index.html"
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 30;
      aws s3 cp ../aws-modern-application-workshop/module-1/web/index.html s3://${self.bucket}/index.html
    EOT
  }
}

resource "aws_s3_bucket_policy" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.bucket
  policy = <<POLICY
{
  "Id": "MyPolicy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.static_bucket.bucket}/*"
    }
  ]
}
POLICY
}

output "bucket_url" {
  value = aws_s3_bucket.static_bucket.bucket_domain_name
}
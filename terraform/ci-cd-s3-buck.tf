resource "aws_s3_bucket" "ci_cd_bucket" {
  acl           = "private"
  force_destroy = true
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_s3_bucket_policy" "ci_cd_bucket" {
  bucket = aws_s3_bucket.ci_cd_bucket.bucket
  policy = <<-POLICY
  {
    "Id": "MyPolicy",
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "WhitelistedGet",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${aws_iam_role.code_pipeline.arn}",
            "${aws_iam_role.code_build.arn}"
          ]
        },
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.ci_cd_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.ci_cd_bucket.bucket}"
        ]
      },
      {
        "Sid": "WhitelistedPut",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${aws_iam_role.code_pipeline.arn}",
            "${aws_iam_role.code_build.arn}"
          ]
        },
        "Action": "s3:PutObject",
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.ci_cd_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.ci_cd_bucket.bucket}"
        ]
      }
    ]
  }
  POLICY
}
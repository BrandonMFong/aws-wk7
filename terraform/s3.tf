# S3 bucket 
resource "aws_s3_bucket" "ece592-week7-brando" {
  bucket = "ece592-week7-brando"
  acl    = "private"

  tags = {
    Name = "ece592-week7-brando"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    tags    = {}

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.week7-kms-v2.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_lambda_permission" "week7-bucket-lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:us-east-1:128928602505:function:week6-lambda"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ece592-week6-brando.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.ece592-week7-brando.id

  lambda_function {
    lambda_function_arn = "arn:aws:lambda:us-east-1:128928602505:function:week7-lambda"
    events              = ["s3:ObjectCreated:*"]
  }
}

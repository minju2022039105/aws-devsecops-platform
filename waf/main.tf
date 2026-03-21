resource "aws_s3_bucket" "waf_logs" {
  bucket        = "aws-waf-logs-minju-0417-project"
  force_destroy = true
}

# 1. 퍼블릭 액세스 차단 (Result #1, #2, #4, #5, #10 해결)
resource "aws_s3_bucket_public_access_block" "waf_logs_block" {
  bucket = aws_s3_bucket.waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. 기본 암호화 설정 (Result #3, #6 해결)
# KMS 키를 사용하여 암호화 (Customer Managed Key 권장 사항 반영)
resource "aws_kms_key" "waf_s3_key" {
  description             = "KMS key for WAF S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs_encryption" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.waf_s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 3. 버전 관리 활성화 (Result #9 해결)
resource "aws_s3_bucket_versioning" "waf_logs_versioning" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 4. 액세스 로깅 활성화 (Result #8 해결)
# 실제 프로젝트에서는 별도의 로깅 전용 버킷을 지정하는 것이 좋으나, 우선 자기 자신으로 설정
resource "aws_s3_bucket_logging" "waf_logs_logging" {
  bucket = aws_s3_bucket.waf_logs.id

  target_bucket = aws_s3_bucket.waf_logs.id
  target_prefix = "log/"
}

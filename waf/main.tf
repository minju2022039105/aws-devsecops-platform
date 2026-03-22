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

# 5. 진짜 WAF Web ACL 생성 (규칙 추가 버전!)
resource "aws_wafv2_web_acl" "main" {
  name        = "devsecops-waf"
  description = "WAF for ALB with Managed Rules"
  scope       = "REGIONAL"

  default_action {
    allow {} 
  }

  # [규칙 1] 가장 일반적인 웹 공격 방어 (Common Rule Set)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1 # 우선순위 1번
    override_action {
      none {} # 차단(Block)을 그대로 수행함
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # [규칙 2] SQL 인젝션 방어 (SQLi Rule Set)
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2 # 우선순위 2번
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsSQLiRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "devsecopsWAF"
    sampled_requests_enabled   = true
  }
}

# 6. WAF 로깅 설정 (방금 만든 S3 버킷과 WAF를 연결)
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_s3_bucket.waf_logs.arn] # 위에서 만든 버킷 ARN
}
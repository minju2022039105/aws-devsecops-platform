# 1. WAF 로그 저장용 S3 (중복 방지를 위해 이름을 고유하게 변경)
resource "aws_s3_bucket" "waf_logs" {
  # 버킷 이름을 다른 사용자와 겹치지 않게 'minju-0417-project' 등으로 수정했습니다.
  bucket        = "aws-waf-logs-minju-0417-project" 
  force_destroy = true
}

# 5단계 보안 규칙이 적용된 Web ACL
resource "aws_wafv2_web_acl" "main" {
  name     = "devsecops-advanced-waf"
  scope    = "REGIONAL"

  default_action {
    allow {}
  }

  # Priority 0: Geo-Blocking (한국 전용)
  rule {
    name     = "GeoBlockingRule"
    priority = 0
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["KR"]
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockingMetric"
      sampled_requests_enabled   = true
    }
  }

  # Priority 1: SQL Injection (Managed)
  rule {
    name     = "AWSManagedRulesSQLi"
    priority = 1
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
      metric_name                = "SQLiMetric"
      sampled_requests_enabled   = true
    }
  }

  # Priority 2: Common Attacks (XSS 포함)
  rule {
    name     = "AWSManagedRulesCommon"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonMetric"
      sampled_requests_enabled   = true
    }
  }

  # Priority 3: Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputs"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadInputMetric"
      sampled_requests_enabled   = true
    }
  }

  # Priority 4: IP Reputation (악성 IP 리스트)
  rule {
    name     = "AWSManagedRulesAmazonIpReputation"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputationMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "devsecops-waf-main"
    sampled_requests_enabled   = true
  }
}

# 로그 연결
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}
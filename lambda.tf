# 1. 소스 코드 압축 (폴더 전체를 압축)
data "archive_file" "lambda_zip" {
  type        = "zip"
  # 민주님의 실제 경로를 절대 경로로 지정했습니다.
  source_dir  = "/home/march/aws-devsecops-platform/Security-AIOps-IsolationForest/lambda"
  output_path = "${path.module}/lambda_functions.zip"
}

# 2. SecurityAnalyzer (분석가)
resource "aws_lambda_function" "analyzer" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "SecurityAnalyzer"
  
  # 모듈 내의 IAM Role ARN을 참조 (identity 모듈 기준)
  role          = module.identity.ec2_role_arn
  
  handler       = "lambda_security_analyzer.handler" 
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      ATHENA_DB     = "monitoring_db"
      ATHENA_TABLE  = "aiops_results"
      ATHENA_OUTPUT = "s3://aws-waf-logs-minju-0417-project/athena-results/"
      PREVENTER_FN  = "SecurityPreventer"
    }
  }
}

# 3. SecurityPreventer (방어자)
resource "aws_lambda_function" "preventer" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "SecurityPreventer"
  
  # 모듈 내의 IAM Role ARN을 참조
  role          = module.identity.ec2_role_arn
  
  handler       = "lambda_security_preventer.handler"
  runtime       = "python3.11"
}

# 4. S3 트리거 권한 (S3가 람다를 깨울 수 있게 허용)
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyzer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::aws-waf-logs-minju-0417-project"
}

# 5. S3 이벤트 알림 설정 (파일 생성 시 람다 호출)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "aws-waf-logs-minju-0417-project"

  lambda_function {
    lambda_function_arn = aws_lambda_function.analyzer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "results/"
    filter_suffix       = ".json"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ECRリポジトリ
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.app_name
    Environment = var.environment
  }
}

# Lambda実行ロール
resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-lambda-role"
    Environment = var.environment
  }
}

# Lambda基本実行ポリシー
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# CloudWatch Logs グループ
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-logs"
    Environment = var.environment
  }
}

# Lambda関数
resource "aws_lambda_function" "app" {
  function_name = var.app_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.app.repository_url}:latest"
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      FLASK_ENV = var.environment
    }
  }

  tags = {
    Name        = var.app_name
    Environment = var.environment
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# Lambda関数URL（シンプルなHTTPエンドポイント）
resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    max_age          = 86400
  }
}

# API Gateway HTTP API（オプション：より高度な設定が必要な場合）
resource "aws_apigatewayv2_api" "app" {
  count         = var.use_api_gateway ? 1 : 0
  name          = "${var.app_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
    max_age      = 300
  }

  tags = {
    Name        = "${var.app_name}-api"
    Environment = var.environment
  }
}

# API Gateway統合
resource "aws_apigatewayv2_integration" "app" {
  count            = var.use_api_gateway ? 1 : 0
  api_id           = aws_apigatewayv2_api.app[0].id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.app.invoke_arn

  payload_format_version = "2.0"
}

# API Gatewayルート
resource "aws_apigatewayv2_route" "app" {
  count     = var.use_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.app[0].id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.app[0].id}"
}

# API Gatewayステージ
resource "aws_apigatewayv2_stage" "app" {
  count       = var.use_api_gateway ? 1 : 0
  api_id      = aws_apigatewayv2_api.app[0].id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.app_name}-stage"
    Environment = var.environment
  }
}

# API Gateway用CloudWatch Logs
resource "aws_cloudwatch_log_group" "api_logs" {
  count             = var.use_api_gateway ? 1 : 0
  name              = "/aws/apigateway/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-api-logs"
    Environment = var.environment
  }
}

# Lambda実行権限（API Gateway用）
resource "aws_lambda_permission" "api_gateway" {
  count         = var.use_api_gateway ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.app[0].execution_arn}/*/*"
}

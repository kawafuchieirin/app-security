output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.app.function_name
}

output "lambda_function_url" {
  description = "Lambda function URL endpoint"
  value       = aws_lambda_function_url.app.function_url
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL (if enabled)"
  value       = var.use_api_gateway ? aws_apigatewayv2_stage.app[0].invoke_url : null
}

output "app_url" {
  description = "Application URL (Lambda Function URL or API Gateway)"
  value       = var.use_api_gateway ? aws_apigatewayv2_stage.app[0].invoke_url : aws_lambda_function_url.app.function_url
}

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN for OIDC"
  value       = var.github_repository != "" ? aws_iam_role.github_actions.arn : null
}

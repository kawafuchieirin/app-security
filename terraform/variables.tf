variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "flask-todo-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "use_api_gateway" {
  description = "Whether to use API Gateway (true) or Lambda Function URL (false)"
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "GitHub repository in the format 'owner/repo'"
  type        = string
  default     = ""
}

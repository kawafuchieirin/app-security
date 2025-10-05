# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flask learning sample application - a simple task management app demonstrating core Flask concepts.

## Repository Structure

```
app-security/
├── app.py                      # Main Flask application
├── lambda_handler.py           # Lambda handler wrapper
├── requirements.txt            # Python dependencies
├── pyproject.toml              # Poetry configuration
├── Dockerfile                  # Docker Compose用
├── Dockerfile.lambda           # AWS Lambda用
├── docker-compose.yml          # Docker Compose設定
├── deploy.sh                   # Lambda自動デプロイスクリプト
├── DEPLOYMENT.md               # デプロイメントガイド
├── templates/                  # Jinja2 templates
│   ├── base.html              # Base template with navigation
│   ├── index.html             # Task list page
│   └── about.html             # About page
├── static/                     # Static assets
│   └── css/
│       └── style.css          # Application styles
└── terraform/                  # Terraform configuration
    ├── main.tf                # Main infrastructure
    ├── variables.tf           # Variable definitions
    ├── outputs.tf             # Output definitions
    └── terraform.tfvars.example  # Example variables
```

## Development Commands

### Initial Setup
```bash
# Install dependencies with Poetry
poetry install
```

### Running the Application
```bash
# Run development server with Poetry
poetry run python app.py

# Or using Flask CLI
poetry run flask --app app run
```

The application will be available at `http://localhost:1000` (configured in app.py)

### Running with Docker Compose
```bash
# ビルドして起動
docker-compose up --build

# バックグラウンドで起動
docker-compose up -d

# 停止
docker-compose down
```

### Deploying to AWS Lambda

#### GitHub Actions (完全自動化 - 推奨)
GitHub Actionsでインフラのセットアップからデプロイまで自動化されます。

```bash
# 初回セットアップ
# 1. GitHub Secretsに AWS_ACCESS_KEY_ID と AWS_SECRET_ACCESS_KEY を追加
# 2. Actions → Setup AWS Infrastructure → Run workflow
# 3. 完了後、表示されたAWS_ROLE_ARNをGitHub Secretsに追加

# デプロイ（2回目以降）
git push origin main
# 自動的に Terraform チェック → Docker ビルド → ECR プッシュ → Lambda 更新
```

詳細は [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) を参照。

#### ローカルデプロイ
```bash
# 自動デプロイスクリプト
./deploy.sh

# 手動デプロイ
cd terraform
terraform init
terraform plan
terraform apply

# 詳細はDEPLOYMENT.mdを参照
```

### Other Useful Commands
```bash
# Add a new dependency
poetry add <package-name>

# Add a development dependency
poetry add --group dev <package-name>

# Update dependencies
poetry update

# Show installed packages
poetry show

# Activate Poetry shell (alternative to using "poetry run")
poetry shell
```

## Application Architecture

This is a simple Flask application demonstrating:

- **Routing**: Multiple routes (`/`, `/add`, `/complete/<id>`, `/delete/<id>`, `/about`)
- **Template Inheritance**: Using `base.html` as a parent template
- **Form Handling**: POST requests to add tasks
- **Flash Messages**: User feedback for actions
- **In-Memory Storage**: Tasks stored in a Python list (no database)

Note: Data is not persisted and will be lost when the server restarts. This is intentional for learning purposes.

## Deployment Architecture

The application supports multiple deployment options:

1. **Local Development**: Poetry + Flask development server
2. **Docker Compose**: Containerized local deployment
3. **AWS Lambda**: Serverless deployment with Terraform
   - ECR: Docker image storage
   - Lambda Function URL or API Gateway: HTTP endpoint
   - CloudWatch Logs: Application logging
4. **CI/CD**: GitHub Actions for automated deployment
   - OIDC authentication (no long-term credentials)
   - Automatic deployment on push to main branch
   - ECR image push and Lambda function update

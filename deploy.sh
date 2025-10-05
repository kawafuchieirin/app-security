#!/bin/bash
set -e

# AWS Lambda用のFlaskアプリケーションデプロイスクリプト

# カラー出力用
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Flask App Lambda Deployment ===${NC}"

# AWS設定確認
AWS_REGION=${AWS_REGION:-ap-northeast-1}
APP_NAME=${APP_NAME:-flask-todo-app}

echo -e "${BLUE}AWS Region: ${GREEN}${AWS_REGION}${NC}"
echo -e "${BLUE}App Name: ${GREEN}${APP_NAME}${NC}"

# AWS認証情報確認
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please configure AWS credentials using 'aws configure'"
    exit 1
fi

# Terraformディレクトリに移動
cd terraform

# Terraform初期化
echo -e "\n${BLUE}Step 1: Initializing Terraform...${NC}"
terraform init

# Terraform plan
echo -e "\n${BLUE}Step 2: Planning Terraform changes...${NC}"
terraform plan -out=tfplan

# Terraform apply
echo -e "\n${BLUE}Step 3: Applying Terraform changes...${NC}"
terraform apply tfplan
rm -f tfplan

# ECRリポジトリURLを取得
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
echo -e "\n${GREEN}ECR Repository URL: ${ECR_REPO_URL}${NC}"

# ECRログイン
echo -e "\n${BLUE}Step 4: Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}

# Dockerイメージをビルド
echo -e "\n${BLUE}Step 5: Building Docker image...${NC}"
cd ..
docker build -f Dockerfile.lambda -t ${APP_NAME}:latest .

# イメージにタグ付け
echo -e "\n${BLUE}Step 6: Tagging Docker image...${NC}"
docker tag ${APP_NAME}:latest ${ECR_REPO_URL}:latest

# ECRにプッシュ
echo -e "\n${BLUE}Step 7: Pushing Docker image to ECR...${NC}"
docker push ${ECR_REPO_URL}:latest

# Lambda関数を更新
echo -e "\n${BLUE}Step 8: Updating Lambda function...${NC}"
aws lambda update-function-code \
    --function-name ${APP_NAME} \
    --image-uri ${ECR_REPO_URL}:latest \
    --region ${AWS_REGION} > /dev/null

echo -e "\n${BLUE}Step 9: Waiting for Lambda function to be updated...${NC}"
aws lambda wait function-updated \
    --function-name ${APP_NAME} \
    --region ${AWS_REGION}

# 結果を表示
cd terraform
echo -e "\n${GREEN}=== Deployment Successful! ===${NC}"
echo -e "${BLUE}Application URL: ${GREEN}$(terraform output -raw app_url)${NC}"

echo -e "\n${BLUE}You can access your Flask application at the URL above.${NC}"

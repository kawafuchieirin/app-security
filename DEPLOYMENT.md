# AWS Lambda デプロイメントガイド

このガイドでは、FlaskアプリケーションをAWS LambdaとTerraformを使ってデプロイする方法を説明します。

## 前提条件

### 必要なツール

- [AWS CLI](https://aws.amazon.com/cli/) (v2.0以降)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0以降)
- [Docker](https://www.docker.com/get-started) (v20.10以降)
- AWS アカウントと適切なIAM権限

### AWS認証情報の設定

```bash
aws configure
```

以下の情報を入力:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (例: ap-northeast-1)
- Default output format (例: json)

## デプロイ手順

### 方法1: GitHub Actions (CI/CD) - 推奨

GitHub Actionsを使用すると、mainブランチへのプッシュで自動的にLambdaがデプロイされます。

#### セットアップ手順

1. **Terraformでインフラをデプロイ**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集してgithub_repositoryを設定
vim terraform.tfvars
```

terraform.tfvarsの例:
```hcl
aws_region = "ap-northeast-1"
app_name = "flask-todo-app"
environment = "production"
github_repository = "your-username/app-security"  # 実際のリポジトリ名に変更
```

2. **Terraformを実行**

```bash
terraform init
terraform apply
```

3. **GitHub Actions用のロールARNを取得**

```bash
terraform output github_actions_role_arn
```

出力例: `arn:aws:iam::123456789012:role/flask-todo-app-github-actions-role`

4. **GitHub SecretsにロールARNを設定**

リポジトリの Settings → Secrets and variables → Actions で以下を追加:

- **Name**: `AWS_ROLE_ARN`
- **Value**: 上記で取得したロールARN

5. **デプロイ**

```bash
git add .
git commit -m "Add Lambda deployment"
git push origin main
```

これで、mainブランチにプッシュするたびに自動的にLambdaがデプロイされます。

GitHub Actionsの実行状況は、リポジトリの「Actions」タブで確認できます。

### 方法2: 自動デプロイスクリプト（ローカル開発用）

```bash
# デプロイスクリプトを実行
./deploy.sh
```

このスクリプトは以下を自動実行します:
1. Terraformの初期化とインフラ構築
2. Dockerイメージのビルド
3. ECRへのプッシュ
4. Lambda関数の更新

### 方法2: 手動デプロイ

#### ステップ1: Terraformの設定

```bash
# terraform.tfvarsファイルを作成
cd terraform
cp terraform.tfvars.example terraform.tfvars

# 必要に応じて terraform.tfvars を編集
vim terraform.tfvars
```

#### ステップ2: インフラのデプロイ

```bash
# Terraform初期化
terraform init

# 変更内容の確認
terraform plan

# インフラをデプロイ
terraform apply
```

#### ステップ3: Dockerイメージのビルドとプッシュ

```bash
# ECRリポジトリURLを取得
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)

# ECRにログイン
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

# Dockerイメージをビルド
cd ..
docker build -f Dockerfile.lambda -t flask-todo-app:latest .

# イメージにタグ付け
docker tag flask-todo-app:latest $ECR_REPO_URL:latest

# ECRにプッシュ
docker push $ECR_REPO_URL:latest
```

#### ステップ4: Lambda関数の更新

```bash
# Lambda関数を最新のイメージで更新
aws lambda update-function-code \
    --function-name flask-todo-app \
    --image-uri $ECR_REPO_URL:latest \
    --region $AWS_REGION

# 更新完了を待機
aws lambda wait function-updated \
    --function-name flask-todo-app \
    --region $AWS_REGION
```

## デプロイ後の確認

```bash
# アプリケーションURLを取得
cd terraform
terraform output app_url
```

表示されたURLにブラウザでアクセスして、アプリケーションが動作していることを確認します。

## アーキテクチャ

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   ユーザー   │────>│ Lambda URL   │────>│   Lambda    │
│             │     │ or API GW    │     │  (Flask)    │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                                               ▼
                                         ┌─────────────┐
                                         │     ECR     │
                                         │   (Image)   │
                                         └─────────────┘
```

### 主要なコンポーネント

- **Lambda Function**: Flaskアプリケーションを実行
- **ECR (Elastic Container Registry)**: Dockerイメージを保存
- **Lambda Function URL**: シンプルなHTTPエンドポイント（デフォルト）
- **API Gateway**: より高度なルーティングが必要な場合（オプション）
- **CloudWatch Logs**: アプリケーションログを保存

## 設定のカスタマイズ

### terraform.tfvars

```hcl
# AWSリージョンを変更
aws_region = "us-east-1"

# アプリケーション名を変更
app_name = "my-flask-app"

# 本番環境の場合
environment = "production"

# API Gatewayを使用する場合
use_api_gateway = true
```

### Lambda設定の調整

`terraform/main.tf`で以下を変更可能:

```hcl
resource "aws_lambda_function" "app" {
  timeout     = 30      # タイムアウト（秒）
  memory_size = 512     # メモリサイズ（MB）
  # ...
}
```

## トラブルシューティング

### ログの確認

```bash
# Lambda関数のログを確認
aws logs tail /aws/lambda/flask-todo-app --follow --region ap-northeast-1
```

### Lambda関数の状態確認

```bash
aws lambda get-function --function-name flask-todo-app --region ap-northeast-1
```

### よくあるエラー

#### 1. Docker build エラー

```bash
# Docker Buildxを使用（M1/M2 Macの場合）
docker buildx build --platform linux/amd64 -f Dockerfile.lambda -t flask-todo-app:latest .
```

#### 2. ECRログインエラー

```bash
# AWS CLIバージョンを確認
aws --version

# 認証情報を確認
aws sts get-caller-identity
```

#### 3. Terraformエラー

```bash
# Terraform状態を確認
terraform state list

# 特定のリソースを再作成
terraform taint aws_lambda_function.app
terraform apply
```

#### 4. GitHub Actionsエラー

**エラー: "Error: User: arn:aws:sts::... is not authorized to perform: sts:AssumeRoleWithWebIdentity"**

原因: GitHub Secretsの設定ミスまたはIAMロールの権限不足

解決方法:
```bash
# 1. ロールARNが正しく設定されているか確認
cd terraform
terraform output github_actions_role_arn

# 2. GitHub Secretsの AWS_ROLE_ARN を確認
# リポジトリ Settings → Secrets and variables → Actions

# 3. github_repository変数が正しく設定されているか確認
grep github_repository terraform.tfvars
```

**エラー: "Error: calling the invoke lambda api operation: service closed the connection without sending a response"**

原因: Lambda関数のタイムアウトまたはメモリ不足

解決方法:
```bash
# Lambda関数のメモリとタイムアウトを増やす
# terraform/main.tf を編集
terraform apply
```

**GitHub Actionsのログを確認する方法:**

1. リポジトリの「Actions」タブを開く
2. 失敗したワークフローをクリック
3. 各ステップのログを確認

## 更新とメンテナンス

### GitHub Actionsによる自動デプロイ

GitHub Actionsを設定済みの場合は、単純にmainブランチにプッシュするだけで自動デプロイされます：

```bash
git add .
git commit -m "Update application"
git push origin main
```

デプロイの進行状況はGitHub Actionsのタブで確認できます。

### アプリケーションコードの更新

```bash
# 変更をコミット後、再デプロイ
./deploy.sh
```

### インフラの更新

```bash
cd terraform
terraform plan
terraform apply
```

### リソースの削除

```bash
cd terraform
terraform destroy
```

**注意**: ECRに保存されているイメージは手動で削除する必要があります。

```bash
# ECRリポジトリを完全削除
aws ecr delete-repository \
    --repository-name flask-todo-app \
    --force \
    --region ap-northeast-1
```

## セキュリティ考慮事項

### 本番環境への推奨設定

1. **Lambda Function URLの認証を有効化**
   ```hcl
   resource "aws_lambda_function_url" "app" {
     authorization_type = "AWS_IAM"  # 認証を要求
   }
   ```

2. **シークレットキーの環境変数化**
   ```hcl
   environment {
     variables = {
       SECRET_KEY = var.flask_secret_key  # terraform.tfvarsで設定
     }
   }
   ```

3. **VPC内でLambdaを実行**（データベース接続時など）
   ```hcl
   resource "aws_lambda_function" "app" {
     vpc_config {
       subnet_ids         = var.subnet_ids
       security_group_ids = var.security_group_ids
     }
   }
   ```

4. **CloudWatchアラームの設定**
   - エラー率の監視
   - レイテンシーの監視
   - 実行回数の監視

## コスト最適化

- Lambda無料枠: 月100万リクエスト、400,000 GB-秒の実行時間
- メモリサイズを適切に設定（過剰なメモリは不要）
- CloudWatch Logsの保持期間を調整（デフォルト: 7日）

## 参考リンク

- [AWS Lambda ドキュメント](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Mangum (ASGI/WSGIアダプター)](https://github.com/jordanerguillaume/mangum)
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

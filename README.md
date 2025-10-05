# Flask Todo App

シンプルなタスク管理アプリケーション - Flask学習用のサンプルプロジェクト

## 概要

このプロジェクトは、Flaskの基本的な機能を学習するためのシンプルなタスク管理アプリケーションです。ローカル開発、Docker、AWS Lambdaなど、複数のデプロイメント方法に対応しています。

## 機能

- ✅ タスクの追加・完了・削除
- 📋 タスク一覧表示
- 💬 フラッシュメッセージによるユーザーフィードバック
- 🎨 レスポンシブデザイン

## 技術スタック

### アプリケーション
- **Python 3.13**
- **Flask 3.0** - Webフレームワーク
- **Poetry** - 依存関係管理

### インフラストラクチャ
- **Docker** - コンテナ化
- **AWS Lambda** - サーバーレス実行環境
- **Amazon ECR** - コンテナレジストリ
- **Terraform** - Infrastructure as Code
- **GitHub Actions** - CI/CD

## セットアップ

### 1. ローカル開発環境

#### 依存関係のインストール

```bash
# Poetryを使用
poetry install

# アプリケーションを起動
poetry run python app.py
```

アプリケーションは `http://localhost:1000` で利用できます。

### 2. Docker Compose

```bash
# ビルドして起動
docker-compose up --build

# バックグラウンドで起動
docker-compose up -d

# 停止
docker-compose down
```

### 3. AWS Lambda デプロイ

#### GitHub Actions (推奨)

mainブランチにプッシュすると自動的にLambdaにデプロイされます。

**初回セットアップ:**

```bash
# 1. terraform.tfvarsを設定
cd terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # github_repositoryを設定

# 2. Terraformを実行
terraform init
terraform apply

# 3. ロールARNを取得
terraform output github_actions_role_arn

# 4. GitHub Secretsに設定
# Settings → Secrets and variables → Actions
# Name: AWS_ROLE_ARN
# Value: 上記のロールARN

# 5. デプロイ
git push origin main
```

#### ローカルからデプロイ

```bash
# AWS認証情報を設定
aws configure

# 自動デプロイスクリプトを実行
./deploy.sh
```

詳細なデプロイ手順は [DEPLOYMENT.md](DEPLOYMENT.md) を参照してください。

## プロジェクト構造

```
app-security/
├── app.py                      # メインアプリケーション
├── lambda_handler.py           # Lambda handler
├── pyproject.toml              # Poetry設定
├── requirements.txt            # Python依存関係
├── Dockerfile                  # Docker Compose用
├── Dockerfile.lambda           # AWS Lambda用
├── docker-compose.yml          # Docker Compose設定
├── deploy.sh                   # デプロイスクリプト
├── DEPLOYMENT.md               # デプロイメントガイド
├── CLAUDE.md                   # Claude Code用ガイド
├── templates/                  # Jinja2テンプレート
│   ├── base.html
│   ├── index.html
│   └── about.html
├── static/                     # 静的ファイル
│   └── css/
│       └── style.css
├── terraform/                  # Terraformインフラ定義
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── github-actions.tf
│   └── terraform.tfvars.example
└── .github/
    └── workflows/
        └── deploy.yml          # GitHub Actions CI/CD
```

## デプロイメントアーキテクチャ

### AWS Lambda構成

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

### CI/CD パイプライン

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ Git Push    │────>│GitHub Actions│────>│ECR Push     │
│  to main    │     │              │     │             │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                                               ▼
                                         ┌─────────────┐
                                         │Lambda Update│
                                         └─────────────┘
```

## 開発

### コードフォーマット

このプロジェクトではpre-commitフックを使用しています。

```bash
# pre-commitのインストール
poetry install --with dev

# pre-commitフックの有効化
poetry run pre-commit install

# 手動実行
poetry run pre-commit run --all-files
```

使用しているツール:
- **black** - コードフォーマッター
- **isort** - import文のソート
- **flake8** - リンター
- **yamllint** - YAML検証

### 依存関係の追加

```bash
# 本番依存関係
poetry add <package-name>

# 開発依存関係
poetry add --group dev <package-name>
```

## 環境変数

開発環境では以下の環境変数を設定できます:

```bash
# Flask設定
export FLASK_ENV=development
export FLASK_DEBUG=1

# AWS設定（デプロイ時）
export AWS_REGION=ap-northeast-1
export APP_NAME=flask-todo-app
```

## セキュリティに関する注意

### 本番環境への推奨事項

1. **シークレットキーの変更**
   - `app.py`の`secret_key`を環境変数から読み込むように変更

2. **Lambda Function URLの認証**
   - 本番環境ではOIDCまたはIAM認証を有効化

3. **HTTPS通信**
   - Lambda Function URLとAPI GatewayはデフォルトでHTTPS対応

4. **環境変数の保護**
   - AWS Secrets ManagerまたはParameter Storeの使用を検討

詳細は [DEPLOYMENT.md](DEPLOYMENT.md) のセキュリティセクションを参照してください。

## トラブルシューティング

### ローカル開発

```bash
# Poetryのキャッシュをクリア
poetry cache clear pypi --all

# 仮想環境を再作成
poetry env remove python
poetry install
```

### Docker

```bash
# イメージを再ビルド
docker-compose build --no-cache

# ログを確認
docker-compose logs -f
```

### AWS Lambda

```bash
# Lambda関数のログを確認
aws logs tail /aws/lambda/flask-todo-app --follow --region ap-northeast-1

# Lambda関数の状態確認
aws lambda get-function --function-name flask-todo-app --region ap-northeast-1
```

## 制限事項

- **データ永続化なし**: タスクはメモリ内に保存され、再起動で消失します
- **単一インスタンス**: データベースなしのため、複数インスタンスでのデータ共有不可
- **学習目的**: 本番環境での使用には追加の機能（DB、認証等）が必要

## ライセンス

このプロジェクトは学習目的のサンプルアプリケーションです。

## リソース

- [Flask ドキュメント](https://flask.palletsprojects.com/)
- [AWS Lambda ドキュメント](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)

## 詳細なドキュメント

- [DEPLOYMENT.md](DEPLOYMENT.md) - 詳細なデプロイメント手順
- [CLAUDE.md](CLAUDE.md) - Claude Code用のプロジェクトガイド

# GitHub Actions CI/CD セットアップガイド

このガイドでは、GitHub ActionsでAWS Lambdaへの自動デプロイを設定する手順を説明します。

## 2つのセットアップ方法

### 方法1: GitHub Actionsで完全自動化（推奨）

GitHub Actionsのワークフローを使用してインフラのセットアップからデプロイまで全て自動化します。

### 方法2: 手動セットアップ

Terraformをローカルで実行してインフラを構築し、GitHub Actionsはデプロイのみを行います。

---

## 方法1: GitHub Actionsで完全自動化（推奨）

### 前提条件

- GitHubリポジトリが作成済み
- AWS アカウントと適切な権限
- AWS Access KeyとSecret Key（初回セットアップのみ）

### セットアップ手順

#### ステップ1: AWS認証情報をGitHub Secretsに追加

1. GitHubリポジトリを開く
2. **Settings** → **Secrets and variables** → **Actions**
3. 以下の2つのSecretを追加:

**Secret 1:**
- Name: `AWS_ACCESS_KEY_ID`
- Value: あなたのAWS Access Key ID

**Secret 2:**
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: あなたのAWS Secret Access Key

> **注意**: これらの認証情報は初回セットアップのみに使用されます。インフラ作成後はOIDCロールによる認証に切り替わります。

#### ステップ2: インフラセットアップワークフローを実行

1. GitHubリポジトリの **Actions** タブを開く
2. **Setup AWS Infrastructure** ワークフローを選択
3. **Run workflow** をクリック
4. 以下のパラメータを入力:
   - **AWS Region**: `ap-northeast-1` (または任意のリージョン)
   - **Application Name**: `flask-todo-app`
   - **Environment**: `production`
   - **GitHub Repository**: `owner/repo` (例: `octocat/app-security`)
5. **Run workflow** をクリック

#### ステップ3: ワークフローの完了を待つ

ワークフローが完了すると、以下のリソースが作成されます:
- ECRリポジトリ
- Lambda関数
- IAMロール（Lambda実行用、GitHub Actions用）
- CloudWatch Logsグループ

ワークフローの Summary に表示される **AWS_ROLE_ARN** をコピーしてください。

#### ステップ4: AWS_ROLE_ARNをGitHub Secretsに追加

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** をクリック
3. 以下を入力:
   - Name: `AWS_ROLE_ARN`
   - Value: ステップ3でコピーしたロールARN
4. **Add secret** をクリック

#### ステップ5: AWS Access Keyを削除（オプション、推奨）

セキュリティ向上のため、初回セットアップ後はAccess Keyを削除することを推奨します:

1. **Settings** → **Secrets and variables** → **Actions**
2. `AWS_ACCESS_KEY_ID` を削除
3. `AWS_SECRET_ACCESS_KEY` を削除

以降はOIDCロール認証が使用されます。

#### ステップ6: 自動デプロイのテスト

```bash
git add .
git commit -m "Setup GitHub Actions deployment"
git push origin main
```

mainブランチにプッシュすると、自動的に以下が実行されます:
1. Terraformで変更をチェック（変更がある場合のみ適用）
2. Dockerイメージのビルド
3. ECRへのプッシュ
4. Lambda関数の更新

---

## 方法2: 手動セットアップ

### 前提条件

- GitHubリポジトリが作成済み
- AWS アカウントと適切な権限
- ローカルにTerraformがインストール済み

### セットアップ手順

### ステップ1: Terraformでインフラをデプロイ

#### 1-1. terraform.tfvarsを作成

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

#### 1-2. terraform.tfvarsを編集

```bash
vim terraform.tfvars
```

以下の内容を設定します：

```hcl
aws_region = "ap-northeast-1"
app_name = "flask-todo-app"
environment = "production"
github_repository = "your-username/app-security"  # ← 実際のリポジトリ名に変更
```

**重要**: `github_repository` は正確に `owner/repo` の形式で設定してください。

例:
- ✅ 正しい: `"octocat/my-app"`
- ❌ 間違い: `"github.com/octocat/my-app"`
- ❌ 間違い: `"my-app"`

#### 1-3. Terraformを実行

```bash
# 初期化
terraform init

# 変更内容を確認
terraform plan

# 実行（yes と入力）
terraform apply
```

成功すると、以下のようなリソースが作成されます：
- ECRリポジトリ
- Lambda関数
- Lambda実行ロール
- GitHub Actions用OIDCプロバイダー
- GitHub Actions用IAMロール

### ステップ2: GitHub Actions用のロールARNを取得

```bash
terraform output github_actions_role_arn
```

出力例:
```
arn:aws:iam::123456789012:role/flask-todo-app-github-actions-role
```

このARNをコピーしてください。

### ステップ3: GitHub Secretsに設定

#### 3-1. GitHubリポジトリのSettings を開く

1. ブラウザでGitHubリポジトリを開く
2. 上部メニューの「Settings」をクリック
3. 左サイドバーの「Secrets and variables」→「Actions」をクリック

#### 3-2. New repository secret をクリック

#### 3-3. Secretを追加

- **Name**: `AWS_ROLE_ARN`
- **Secret**: ステップ2でコピーしたARN（例: `arn:aws:iam::123456789012:role/flask-todo-app-github-actions-role`）

#### 3-4. 「Add secret」をクリック

### ステップ4: デプロイをテスト

```bash
# 変更をコミット
git add .
git commit -m "Add GitHub Actions deployment"
git push origin main
```

### ステップ5: デプロイを確認

1. GitHubリポジトリの「Actions」タブを開く
2. 最新のワークフロー実行をクリック
3. 各ステップの進行状況を確認

成功すると、以下のステップが全て緑色のチェックマークになります：
- ✅ Checkout code
- ✅ Validate AWS Role ARN
- ✅ Configure AWS credentials
- ✅ Login to Amazon ECR
- ✅ Build, tag, and push image to Amazon ECR
- ✅ Update Lambda function
- ✅ Wait for Lambda function update
- ✅ Deployment summary

## トラブルシューティング

### エラー1: "AWS_ROLE_ARN secret is not set!"

**原因**: GitHub Secretsに `AWS_ROLE_ARN` が設定されていない

**解決方法**:
1. ステップ3を再確認
2. Secretの名前が正確に `AWS_ROLE_ARN` になっているか確認（大文字小文字を区別）
3. Secretが正しいリポジトリに設定されているか確認

### エラー2: "Credentials could not be loaded"

**原因**: IAMロールの信頼関係が正しく設定されていない

**解決方法**:

```bash
# 1. github_repository変数を確認
cd terraform
grep github_repository terraform.tfvars

# 2. 出力が正しいか確認（owner/repo形式）
# 間違っている場合は修正して再度 terraform apply

# 3. Terraformを再適用
terraform apply

# 4. 新しいロールARNを取得
terraform output github_actions_role_arn

# 5. GitHub Secretsを更新
```

### エラー3: "Repository not found" (ECR)

**原因**: ECRリポジトリが作成されていない、またはリージョンが違う

**解決方法**:

```bash
# ECRリポジトリの存在を確認
aws ecr describe-repositories --region ap-northeast-1

# Terraformの状態を確認
terraform state list | grep ecr

# 必要に応じて再作成
terraform apply
```

### エラー4: "Lambda function not found"

**原因**: Lambda関数が存在しない、または名前が違う

**解決方法**:

```bash
# Lambda関数の存在を確認
aws lambda get-function --function-name flask-todo-app --region ap-northeast-1

# Terraformで関数名を確認
terraform output lambda_function_name

# .github/workflows/deploy.yml の LAMBDA_FUNCTION_NAME を確認
```

### エラー5: GitHub Actionsが実行されない

**原因**: ワークフローファイルの配置場所が間違っている

**解決方法**:

正しいパス: `.github/workflows/deploy.yml`

```bash
# ファイルの場所を確認
ls -la .github/workflows/deploy.yml

# 存在しない場合は配置を確認
```

## セキュリティのベストプラクティス

### 1. 最小権限の原則

GitHub Actions用のIAMロールは、必要最小限の権限のみを持つように設計されています：

- ECR: イメージのpush/pull
- Lambda: 関数コードの更新のみ

### 2. OIDC認証

長期的なアクセスキーではなく、OIDC（OpenID Connect）を使用することで：
- 認証情報の漏洩リスクを軽減
- 自動的にローテーションされる一時的な認証情報を使用
- GitHub Actionsからのみアクセス可能

### 3. ブランチ保護

mainブランチを保護することを推奨：

1. Settings → Branches
2. "Add branch protection rule"
3. Branch name pattern: `main`
4. 以下を有効化：
   - Require a pull request before merging
   - Require status checks to pass before merging

## 日常的な使用方法

セットアップが完了したら、以下の手順で開発・デプロイを行います：

### 開発ワークフロー

```bash
# 1. 新しいブランチを作成
git checkout -b feature/new-feature

# 2. コードを変更
# ... 開発 ...

# 3. ローカルでテスト
poetry run python app.py

# 4. コミット
git add .
git commit -m "Add new feature"

# 5. プッシュ
git push origin feature/new-feature

# 6. GitHubでプルリクエストを作成

# 7. レビュー後、mainにマージ → 自動デプロイ
```

### 手動デプロイ

GitHub Actionsを使わずに手動でデプロイする場合：

```bash
./deploy.sh
```

## よくある質問

### Q1: デプロイにかかる時間は？

**A**: 通常3-5分程度です。
- Dockerビルド: 1-2分
- ECRプッシュ: 1-2分
- Lambda更新: 30秒-1分

### Q2: デプロイ頻度に制限はある？

**A**: GitHub Actionsの無料枠では月2,000分まで利用可能です。1回のデプロイが5分として、月400回程度デプロイ可能です。

### Q3: 複数の環境（dev/staging/prod）に対応できる？

**A**: はい。以下の方法で対応可能：
1. ブランチごとに異なるLambda関数にデプロイ
2. 環境変数で環境を切り替え
3. Terraformワークスペースを使用

詳細はDEPLOYMENT.mdを参照してください。

## 次のステップ

- [DEPLOYMENT.md](DEPLOYMENT.md) - 詳細なデプロイメント手順
- [README.md](README.md) - プロジェクト概要
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

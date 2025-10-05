# クイックスタートガイド

GitHub ActionsでAWS Lambdaへ自動デプロイするための最短手順です。

## 前提条件

- ✅ GitHubリポジトリが作成済み
- ✅ AWSアカウントを持っている
- ✅ AWS Access KeyとSecret Keyを取得済み

## 5ステップでデプロイ

### ステップ1: GitHubリポジトリにコードをプッシュ

```bash
git clone <your-repo-url>
cd app-security
git add .
git commit -m "Initial commit"
git push origin main
```

### ステップ2: AWS認証情報をGitHub Secretsに追加

1. GitHubリポジトリを開く
2. **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
3. 以下の2つを追加:
   - `AWS_ACCESS_KEY_ID`: あなたのAWS Access Key ID
   - `AWS_SECRET_ACCESS_KEY`: あなたのAWS Secret Access Key

### ステップ3: インフラセットアップワークフローを実行

1. **Actions** タブを開く
2. **Setup AWS Infrastructure** を選択
3. **Run workflow** をクリック
4. 以下を入力:
   - **AWS Region**: `ap-northeast-1`
   - **Application Name**: `flask-todo-app`
   - **Environment**: `production`
   - **GitHub Repository**: `あなたのユーザー名/リポジトリ名` (例: `octocat/app-security`)
5. **Run workflow** をクリック

⏱️ 約3-5分待つ

### ステップ4: AWS_ROLE_ARNをGitHub Secretsに追加

1. ワークフロー完了後、Summary に表示される `AWS_ROLE_ARN` をコピー
2. **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
3. 以下を追加:
   - Name: `AWS_ROLE_ARN`
   - Value: コピーしたARN

### ステップ5: デプロイ

```bash
git push origin main
```

✅ 完了！アプリケーションがLambdaにデプロイされました。

## アプリケーションURLの確認

1. **Actions** タブで最新のワークフローを開く
2. **Deployment summary** にアプリケーションURLが表示されます

または、AWS CLIで確認:

```bash
# Lambda関数URLを取得
aws lambda get-function-url-config --function-name flask-todo-app --region ap-northeast-1
```

## 次のステップ

### 開発ワークフロー

```bash
# 1. 機能ブランチを作成
git checkout -b feature/new-feature

# 2. コードを変更
vim app.py

# 3. コミット
git add .
git commit -m "Add new feature"

# 4. プッシュ
git push origin feature/new-feature

# 5. GitHubでプルリクエストを作成

# 6. mainにマージ → 自動デプロイ
```

### セキュリティ向上（推奨）

初回セットアップ後、AWS Access Keyを削除してOIDC認証のみを使用:

1. **Settings** → **Secrets and variables** → **Actions**
2. `AWS_ACCESS_KEY_ID` を削除
3. `AWS_SECRET_ACCESS_KEY` を削除

以降は `AWS_ROLE_ARN` のみで認証されます（より安全）。

## トラブルシューティング

### エラー: "AWS_ROLE_ARN secret is not set!"

→ ステップ4を実施してください

### エラー: "Credentials could not be loaded"

→ ステップ2のAWS認証情報が正しいか確認してください

### エラー: "Repository not found" (ECR)

→ ステップ3のワークフローが正常に完了したか確認してください

## 詳細情報

- [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) - 詳細なセットアップ手順
- [DEPLOYMENT.md](DEPLOYMENT.md) - デプロイメント全般の情報
- [README.md](README.md) - プロジェクト概要

## よくある質問

**Q: デプロイにはどれくらい時間がかかりますか？**

A: 初回: 5-7分、2回目以降: 3-5分

**Q: 費用はかかりますか？**

A: AWS無料枠の範囲内であれば無料です。Lambda: 月100万リクエスト無料、ECR: 500MB無料

**Q: Terraformの知識は必要ですか？**

A: いいえ。GitHub Actionsが全て自動で実行します。

**Q: ローカルでテストできますか？**

A: はい。`poetry run python app.py` または `docker-compose up` で可能です。

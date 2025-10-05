# Pre-commit フック導入ガイド

## Pre-commitとは

Pre-commitは、Gitコミット前に自動的にコードチェックやフォーマットを実行するフレームワークです。これにより、コード品質を保ち、チーム全体で一貫したコーディングスタイルを維持できます。

## このプロジェクトで使用しているフック

このプロジェクトでは以下のツールを使用しています：

### 一般的なフック（pre-commit-hooks）

基本的なコード品質チェック：

- **trailing-whitespace**: 行末の不要な空白を削除
- **end-of-file-fixer**: ファイル末尾に改行を追加
- **check-yaml**: YAMLファイルの構文チェック
- **check-toml**: TOMLファイルの構文チェック
- **check-added-large-files**: 大きなファイルの追加を防止
- **check-merge-conflict**: マージコンフリクトマーカーの検出
- **mixed-line-ending**: 混在した改行コードを統一

### Python関連のフック

#### 1. **Black** - コードフォーマッター
- Pythonコードを自動的に整形
- 一貫したコードスタイルを保証
- 行の長さ: 88文字（デフォルト）

#### 2. **isort** - インポート文の整理
- import文を自動的にソート・整理
- Blackと互換性のある設定

#### 3. **Flake8** - Pythonリンター
- PEP 8スタイルガイド違反をチェック
- コードの問題点を検出
- 設定:
  - 最大行長: 88文字（Blackに合わせて設定）
  - 無視するエラー: E203, W503（Blackとの互換性のため）

### YAML関連のフック

#### 4. **yamllint** - YAMLリンター
- YAMLファイルの構文とスタイルをチェック
- インデント、空白、キーの重複などを検出
- strictモードで実行

## セットアップ手順

### 1. 依存関係のインストール

プロジェクトのセットアップ時に自動的にインストールされます：

```bash
poetry install
```

### 2. Pre-commitフックのインストール

以下のコマンドでGitフックをインストールします：

```bash
poetry run pre-commit install
```

このコマンドを実行すると、`.git/hooks/pre-commit`ファイルが作成され、コミット前に自動的にチェックが実行されるようになります。

### 3. 初回セットアップの確認

すべてのファイルに対して手動でpre-commitを実行してみます：

```bash
poetry run pre-commit run --all-files
```

## 使い方

### 通常のコミット

フックをインストール後は、通常通り`git commit`を実行するだけです：

```bash
git add .
git commit -m "コミットメッセージ"
```

コミット時に自動的に以下が実行されます：
1. Blackによるコードフォーマット
2. Flake8によるスタイルチェック
3. isortによるimport文の整理

### フックが失敗した場合

フックがエラーを検出すると、コミットは中断されます。以下の対応を行ってください：

1. **自動修正される場合**（BlackやIsortなど）
   - ファイルが自動的に修正されます
   - 修正されたファイルを再度ステージング: `git add .`
   - 再度コミット: `git commit -m "メッセージ"`

2. **手動修正が必要な場合**（Flake8エラーなど）
   - エラーメッセージを確認
   - コードを手動で修正
   - 修正後、再度ステージング＆コミット

### 手動でチェックを実行

コミット前に手動でチェックしたい場合：

```bash
# すべてのファイルをチェック
poetry run pre-commit run --all-files

# 特定のファイルのみチェック
poetry run pre-commit run --files app.py

# 特定のフックのみ実行
poetry run pre-commit run black
poetry run pre-commit run flake8
poetry run pre-commit run isort
poetry run pre-commit run yamllint
poetry run pre-commit run trailing-whitespace
```

### フックをスキップ（非推奨）

緊急時のみ、以下のコマンドでフックをスキップできます：

```bash
git commit --no-verify -m "メッセージ"
```

**注意**: これは推奨されません。コード品質を保つため、基本的にはフックを通すようにしてください。

## Pre-commitの更新

定期的にフックのバージョンを更新することを推奨します：

```bash
# フックの自動更新
poetry run pre-commit autoupdate

# 更新後、変更を確認
git diff .pre-commit-config.yaml
```

## YAMLlintの設定

yamllintはデフォルトで厳格なチェックを行います。プロジェクトに合わせて設定をカスタマイズしたい場合、`.yamllint`ファイルを作成してください：

```yaml
# .yamllint の例
extends: default

rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
  comments:
    min-spaces-from-content: 1
```

## トラブルシューティング

### フックが実行されない

```bash
# フックが正しくインストールされているか確認
ls -la .git/hooks/pre-commit

# 再インストール
poetry run pre-commit uninstall
poetry run pre-commit install
```

### キャッシュのクリア

フックの動作がおかしい場合、キャッシュをクリア：

```bash
poetry run pre-commit clean
```

### 特定のファイルを除外

`.pre-commit-config.yaml`に`exclude`を追加：

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.10.0
    hooks:
      - id: black
        exclude: ^migrations/  # 例: migrationsディレクトリを除外
```

## CI/CDでの使用

GitHub ActionsやGitLab CIなどのCI/CD環境でもpre-commitを実行できます：

```yaml
# GitHub Actionsの例
- name: Run pre-commit
  run: |
    poetry install
    poetry run pre-commit run --all-files
```

## 参考リンク

- [Pre-commit公式ドキュメント](https://pre-commit.com/)
- [Pre-commit Hooks](https://github.com/pre-commit/pre-commit-hooks)
- [Black公式ドキュメント](https://black.readthedocs.io/)
- [Flake8公式ドキュメント](https://flake8.pycqa.org/)
- [isort公式ドキュメント](https://pycqa.github.io/isort/)
- [yamllint公式ドキュメント](https://yamllint.readthedocs.io/)

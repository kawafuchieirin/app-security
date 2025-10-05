# Python 3.13をベースイメージとして使用
FROM python:3.13-slim

# 作業ディレクトリを設定
WORKDIR /app

# Poetryのインストール
RUN pip install --no-cache-dir poetry

# pyproject.tomlとpoetry.lockをコピー（依存関係の定義）
COPY pyproject.toml poetry.lock* ./

# 依存関係をインストール（本番環境用、開発依存関係は除外）
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --only main

# アプリケーションのコードをコピー
COPY . .

# ポート1000を公開
EXPOSE 1000

# Flaskアプリケーションを起動
CMD ["python", "app.py"]

"""
AWS Lambda handler for Flask application
Mangumを使用してFlaskアプリをLambda用にラップ
"""

from mangum import Mangum

from app import app

# Mangumハンドラーを作成（API Gateway統合用）
handler = Mangum(app, lifespan="off")

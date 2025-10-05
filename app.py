from flask import Flask, render_template, request, redirect, url_for, flash
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'  # セッション用のシークレットキー

# タスクを保存するリスト（本番環境ではデータベースを使用）
tasks = []
task_id_counter = 1


@app.route('/')
def index():
    """ホームページ - タスク一覧を表示"""
    return render_template('index.html', tasks=tasks)


@app.route('/add', methods=['POST'])
def add_task():
    """新しいタスクを追加"""
    global task_id_counter

    title = request.form.get('title')
    description = request.form.get('description')

    if title:
        task = {
            'id': task_id_counter,
            'title': title,
            'description': description,
            'completed': False,
            'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        tasks.append(task)
        task_id_counter += 1
        flash('タスクが追加されました！', 'success')
    else:
        flash('タイトルを入力してください', 'error')

    return redirect(url_for('index'))


@app.route('/complete/<int:task_id>')
def complete_task(task_id):
    """タスクを完了にする"""
    for task in tasks:
        if task['id'] == task_id:
            task['completed'] = not task['completed']
            status = '完了' if task['completed'] else '未完了'
            flash(f'タスクを{status}にしました', 'success')
            break
    return redirect(url_for('index'))


@app.route('/delete/<int:task_id>')
def delete_task(task_id):
    """タスクを削除"""
    global tasks
    tasks = [task for task in tasks if task['id'] != task_id]
    flash('タスクが削除されました', 'success')
    return redirect(url_for('index'))


@app.route('/about')
def about():
    """アバウトページ"""
    return render_template('about.html')


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=2000)

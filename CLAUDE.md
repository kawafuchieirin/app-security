# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flask learning sample application - a simple task management app demonstrating core Flask concepts.

## Repository Structure

```
app-security/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── templates/            # Jinja2 templates
│   ├── base.html         # Base template with navigation
│   ├── index.html        # Task list page
│   └── about.html        # About page
└── static/              # Static assets
    └── css/
        └── style.css    # Application styles
```

## Development Commands

### Initial Setup
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# venv\Scripts\activate   # On Windows

# Install dependencies
pip install -r requirements.txt
```

### Running the Application
```bash
# Run development server
python app.py

# Or using Flask CLI
export FLASK_APP=app.py
export FLASK_ENV=development
flask run
```

The application will be available at `http://localhost:5000`

### Deactivate Virtual Environment
```bash
deactivate
```

## Application Architecture

This is a simple Flask application demonstrating:

- **Routing**: Multiple routes (`/`, `/add`, `/complete/<id>`, `/delete/<id>`, `/about`)
- **Template Inheritance**: Using `base.html` as a parent template
- **Form Handling**: POST requests to add tasks
- **Flash Messages**: User feedback for actions
- **In-Memory Storage**: Tasks stored in a Python list (no database)

Note: Data is not persisted and will be lost when the server restarts. This is intentional for learning purposes.

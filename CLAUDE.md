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
# Install dependencies with Poetry
poetry install
```

### Running the Application
```bash
# Run development server with Poetry
poetry run python app.py

# Or using Flask CLI
poetry run flask --app app run
```

The application will be available at `http://localhost:1000` (configured in app.py)

### Other Useful Commands
```bash
# Add a new dependency
poetry add <package-name>

# Add a development dependency
poetry add --group dev <package-name>

# Update dependencies
poetry update

# Show installed packages
poetry show

# Activate Poetry shell (alternative to using "poetry run")
poetry shell
```

## Application Architecture

This is a simple Flask application demonstrating:

- **Routing**: Multiple routes (`/`, `/add`, `/complete/<id>`, `/delete/<id>`, `/about`)
- **Template Inheritance**: Using `base.html` as a parent template
- **Form Handling**: POST requests to add tasks
- **Flash Messages**: User feedback for actions
- **In-Memory Storage**: Tasks stored in a Python list (no database)

Note: Data is not persisted and will be lost when the server restarts. This is intentional for learning purposes.

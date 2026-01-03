# Use Python 3.13 slim image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies including test extras
RUN uv sync --frozen && uv pip install -e ".[test]"

# Copy application code
COPY backend/ ./backend/
COPY frontend/ ./frontend/
COPY docs/ ./docs/
COPY main.py ./

# Create directory for ChromaDB persistence
RUN mkdir -p /app/backend/chroma_db

# Expose port 5000
EXPOSE 5000

# Stay in /app directory for proper Python imports
WORKDIR /app

# Set PYTHONPATH to include backend directory
ENV PYTHONPATH=/app/backend:$PYTHONPATH

# Run uvicorn on port 5000 using the virtual environment directly
CMD ["/app/.venv/bin/uvicorn", "backend.app:app", "--host", "0.0.0.0", "--port", "5000", "--reload"]

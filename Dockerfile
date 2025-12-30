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

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application code
COPY backend/ ./backend/
COPY frontend/ ./frontend/
COPY docs/ ./docs/
COPY main.py ./

# Create directory for ChromaDB persistence
RUN mkdir -p /app/backend/chroma_db

# Expose port 5000
EXPOSE 5000

# Change to backend directory
WORKDIR /app/backend

# Run uvicorn on port 5000
CMD ["uv", "run", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000", "--reload"]

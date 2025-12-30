# Course Materials RAG System

A Retrieval-Augmented Generation (RAG) system designed to answer questions about course materials using semantic search and AI-powered responses.

## Overview

This application is a full-stack web application that enables users to query course materials and receive intelligent, context-aware responses. It uses ChromaDB for vector storage, Anthropic's Claude for AI generation, and provides a web interface for interaction.


## Prerequisites

### Option 1: Docker (Recommended)
- Docker and Docker Compose
- An Anthropic API key (for Claude AI)

### Option 2: Native Python
- Python 3.13 or higher
- uv (Python package manager)
- An Anthropic API key (for Claude AI)
- **For Windows**: Use Git Bash to run the application commands - [Download Git for Windows](https://git-scm.com/downloads/win)

## Setup

**Set up environment variables** (required for both Docker and native installation)

Create a `.env` file in the root directory:
```bash
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

To get an Anthropic API key:
1. Go to [https://console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to "API Keys" and create a new key

## Installation

### Option 1: Docker (Recommended)

No additional installation needed if you have Docker installed.

### Option 2: Native Python

1. **Install uv** (if not already installed)
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Install Python dependencies**
   ```bash
   uv sync
   ```

## Running the Application

### Option 1: Docker (Recommended)

**Start the application:**
```bash
docker-compose up --build -d
```

**The application will be available at:**
- Web Interface: `http://localhost:5000`
- API Documentation: `http://localhost:5000/docs`

**Useful Docker commands:**
```bash
# View logs
docker-compose logs -f

# Stop the application
docker-compose down

# Restart after .env changes
docker-compose down && docker-compose up -d

# Clear all data and restart
docker-compose down -v && docker-compose up --build -d
```

### Option 2: Native Python

**Quick Start** - Use the provided shell script:
```bash
chmod +x run.sh
./run.sh
```

**Manual Start:**
```bash
cd backend
uv run uvicorn app:app --reload --port 8000
```

**The application will be available at:**
- Web Interface: `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`

## Features

- **Semantic Search**: Uses ChromaDB with vector embeddings for intelligent document retrieval
- **AI-Powered Responses**: Leverages Anthropic's Claude for generating contextual answers
- **Course Management**: Automatically processes and indexes course materials from the `docs/` folder
- **Conversation History**: Maintains session-based conversation context
- **Web Interface**: Clean, responsive UI with markdown support and collapsible source citations
- **Hot Reload**: Development mode supports automatic code reloading (both Docker and native)

## Architecture

- **Frontend**: Vanilla JavaScript, HTML, CSS
- **Backend**: FastAPI (Python)
- **Vector Database**: ChromaDB
- **AI Model**: Anthropic Claude (claude-sonnet-4-20250514)
- **Embeddings**: Sentence Transformers (all-MiniLM-L6-v2)

## Adding Course Materials

1. Place your course documents (`.txt`, `.pdf`, or `.docx`) in the `docs/` folder
2. Restart the application
3. The system will automatically process and index the new documents

For detailed documentation, see [CLAUDE.md](CLAUDE.md).


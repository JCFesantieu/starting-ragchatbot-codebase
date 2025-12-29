# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Retrieval-Augmented Generation (RAG) chatbot system for course materials. Users ask questions via a web interface, the system performs semantic search on course documents using ChromaDB, and Claude AI generates contextual answers using retrieved content.

## Running the Application

**Prerequisites:**
- Python 3.13+
- uv package manager:
  - Linux/Mac: `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - Windows (PowerShell): `irm https://astral.sh/uv/install.ps1 | iex`
- Anthropic API key in `.env` file: `ANTHROPIC_API_KEY=sk-ant-api03-...`
  - Copy `.env.example` to `.env` and add your key

**Install dependencies:**
```bash
uv sync
```

**Start the server:**
```bash
./run.sh
# OR manually:
cd backend && uv run uvicorn app:app --reload --port 8000
```

Access at http://localhost:8000

**On Windows:** Use Git Bash to run shell scripts, or use the manual PowerShell command above.

## Architecture Overview

### Request Flow (User Query → Response)

```
Frontend (script.js)
  → POST /api/query
  → FastAPI (app.py)
  → RAG System (rag_system.py) orchestrator
    ├─ Session Manager: retrieve conversation history
    ├─ Tool Manager: provide search tool definitions to Claude
    └─ AI Generator: first Claude API call
        └─ Claude decides to use search tool
        └─ Tool Execution → CourseSearchTool
            └─ Vector Store: ChromaDB semantic search with filters
            └─ Returns top-K chunks with metadata
        └─ AI Generator: second Claude API call with search results
            └─ Claude generates final answer
  → Return (answer, sources) to frontend
  → Render in UI with collapsible sources
```

**Key architectural pattern:** Two-phase AI interaction using Anthropic's tool calling:
1. Claude receives query + tool definitions, decides if search is needed
2. If `stop_reason == "tool_use"`, execute search tool and return results
3. Claude receives search results and generates final answer

### Document Processing Pipeline

```
Raw course file (.txt)
  → DocumentProcessor.process_course_document()
    ├─ Extract metadata (first 3-4 lines): Course Title, Link, Instructor
    ├─ Parse lessons: "Lesson N: Title" + optional "Lesson Link: URL"
    ├─ Accumulate content per lesson
    └─ Chunk text (sentence-based, 800 chars, 100 overlap)
        └─ Add context prefix: "Course X Lesson Y content: {chunk}"
  → Two ChromaDB collections:
    ├─ course_catalog: Course/lesson metadata for fuzzy name matching
    └─ course_content: Searchable text chunks with embeddings
```

**Document format expected:**
```
Course Title: <title>
Course Link: <url>
Course Instructor: <name>

Lesson 0: <lesson title>
Lesson Link: <lesson url>
<content>

Lesson 1: <lesson title>
...
```

### Component Responsibilities

**rag_system.py** - Central orchestrator
- Initializes all components (document processor, vector store, AI generator, session manager, tool manager)
- `add_course_folder()`: Batch process course documents from `docs/` on startup
- `query()`: Main entry point for user queries, coordinates the entire RAG pipeline

**vector_store.py** - ChromaDB wrapper with two collections
- `course_catalog`: Stores course metadata, used for fuzzy course name resolution via semantic search
- `course_content`: Stores text chunks with embeddings (384d via all-MiniLM-L6-v2)
- `search()`: Unified interface with optional `course_name` and `lesson_number` filters
- `_resolve_course_name()`: Fuzzy matching - queries catalog collection to find actual course title

**ai_generator.py** - Claude API integration
- `generate_response()`: Makes API calls with tool support
- `_handle_tool_execution()`: Manages tool calling loop (user → assistant[tool_use] → user[tool_result] → assistant[final])
- Uses `temperature=0` for deterministic responses
- System prompt instructs: "One search per query maximum", answer directly without meta-commentary

**search_tools.py** - Tool definitions and execution
- `CourseSearchTool`: Implements the search interface exposed to Claude
  - `get_tool_definition()`: Returns Anthropic tool schema
  - `execute()`: Calls vector_store.search(), formats results with course/lesson headers
  - `last_sources`: Tracks sources for UI display
- `ToolManager`: Registry pattern for tool management, executes tools by name

**session_manager.py** - Conversation state
- In-memory storage: `sessions[session_id] = [Message(...), ...]`
- `max_history * 2` messages retained (default: 4 messages = 2 exchanges)
- `get_conversation_history()`: Returns formatted string for AI context

**document_processor.py** - Text parsing and chunking
- `chunk_text()`: Sentence-based splitting with regex that handles abbreviations
- Overlap calculation: Counts backwards from end of chunk to include ~100 chars of previous sentences
- Context enrichment: Prepends course/lesson info to each chunk for better retrieval

### Configuration (backend/config.py)

Critical settings:
- `ANTHROPIC_MODEL`: "claude-sonnet-4-20250514"
- `EMBEDDING_MODEL`: "all-MiniLM-L6-v2" (384 dimensions)
- `CHUNK_SIZE`: 800 characters
- `CHUNK_OVERLAP`: 100 characters
- `MAX_RESULTS`: 5 search results
- `MAX_HISTORY`: 2 conversation exchanges
- `CHROMA_PATH`: "./chroma_db" (persistent storage location)

### Data Models (backend/models.py)

- `Course`: title, course_link, instructor, lessons[]
- `Lesson`: lesson_number, title, lesson_link
- `CourseChunk`: content, course_title, lesson_number, chunk_index

### Frontend Architecture

**Single-page app** (frontend/):
- `script.js`: Manages session state, POST requests to `/api/query`, markdown rendering
- `index.html`: Chat UI + sidebar with course stats and suggested questions
- `style.css`: Dark theme, collapsible sources/sections

Session management: Client generates session ID on first message, includes in all subsequent requests for conversation continuity.

## Common Modifications

### Adding a new search filter
1. Add parameter to `CourseSearchTool.get_tool_definition()` input_schema
2. Update `CourseSearchTool.execute()` to accept new parameter
3. Modify `VectorStore.search()` and `_build_filter()` to handle new filter
4. Update chunk metadata in `DocumentProcessor` if needed

### Changing chunk strategy
- Modify `DocumentProcessor.chunk_text()` for different splitting logic
- Update `CHUNK_SIZE` and `CHUNK_OVERLAP` in `config.py`
- Clear and rebuild: `vector_store.clear_all_data()` then restart server

### Adding a new tool for Claude
1. Create new class extending `Tool` in `search_tools.py`
2. Implement `get_tool_definition()` and `execute()`
3. Register in `rag_system.py`: `self.tool_manager.register_tool(YourTool(...))`

### Modifying AI behavior
- Edit system prompt in `ai_generator.py` (line 8-30)
- Adjust `temperature` and `max_tokens` in `base_params` (line 37-41)
- Change model in `config.py` ANTHROPIC_MODEL

## Data Storage

**ChromaDB location:** `backend/chroma_db/` (git-ignored, persistent)
- First run creates vector embeddings (~30 seconds for 4 courses)
- Subsequent runs load existing embeddings (instant startup)
- To rebuild: Delete `chroma_db/` directory and restart server
- Two collections strategy:
  - `course_catalog`: Course/lesson metadata for fuzzy name resolution
  - `course_content`: Full text chunks with embeddings for semantic search

**Course documents:** Place `.txt`, `.pdf`, or `.docx` files in `docs/`
- Auto-loaded on server startup via `app.py` startup event (line 88-98)
- Duplicate detection by course title (won't re-process existing courses)
- To force rebuild: `rag_system.add_course_folder(path, clear_existing=True)`

## API Endpoints

- `POST /api/query` - Main query endpoint
  - Request: `{query: str, session_id?: str}`
  - Response: `{answer: str, sources: str[], session_id: str}`
- `GET /api/courses` - Course statistics
  - Response: `{total_courses: int, course_titles: str[]}`
- `GET /api/docs` - FastAPI auto-generated API documentation at http://localhost:8000/docs

## Testing

**No automated tests currently exist.** The application is tested through:
- Interactive testing via web UI at http://localhost:8000
- FastAPI interactive docs at http://localhost:8000/docs for API endpoint testing
- Manual verification of query responses and source citations

## Debugging Tips

**Trace a query:** Follow query-flow-diagram.txt - shows exact execution path with file:line references

**ChromaDB issues:** Collection creation happens in `vector_store.py:51-58`. Check `chroma_db/` permissions and disk space.

**Tool not being called:** Check `ai_generator.py:83` - `stop_reason` should be "tool_use". If Claude answers directly, system prompt may need adjustment.

**Empty search results:** Verify filter logic in `vector_store.py:_build_filter()`. Use `course_catalog.get()` to check if course exists.

**Session state issues:** Sessions are in-memory only. Server restart clears all sessions. Check `session_manager.py` if history isn't being maintained.

## Important Constraints

**One search per query:** System prompt enforces this to prevent excessive API calls and costs. Tool execution loop in `ai_generator.py:89-135` doesn't iterate - single tool call only.

**No authentication:** API endpoints are unprotected. Add middleware in `app.py` if deploying publicly.

**In-memory sessions:** Sessions lost on restart. Implement persistent session storage if needed (Redis, database, etc.).

**UTF-8 encoding:** Document processor falls back to error-ignoring mode if UTF-8 fails (`document_processor.py:18-21`).

**Windows compatibility:** Use Git Bash for shell scripts. PowerShell alternative: `cd backend; uv run uvicorn app:app --reload --port 8000`

## Development Workflow

**Making code changes:**
1. Backend changes (Python): Server auto-reloads with `--reload` flag
2. Frontend changes (HTML/CSS/JS): Refresh browser (no build step required)
3. Config changes: Restart server manually

**Adding new courses:**
1. Place course file in `docs/` directory
2. Restart server or wait for next startup
3. Verify at http://localhost:8000/api/courses

**Clearing all data:**
```bash
# From project root
rm -rf backend/chroma_db
# Restart server to rebuild embeddings
```

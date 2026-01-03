# RAG Chatbot Test Suite

Comprehensive test suite for the RAG (Retrieval-Augmented Generation) chatbot application.

## Overview

This test suite provides automated testing for all core components of the RAG chatbot system, including:
- API endpoints
- Document processing
- Data models
- Session management

**Current Test Coverage**: 44% overall
- DocumentProcessor: 90%
- SessionManager: 86%
- Models: 100%

## Quick Start

### Running Tests with Docker (Recommended)

```bash
# Run all tests
docker-compose run --rm test

# Run specific test file
docker-compose run --rm test uv run pytest backend/tests/test_api.py -v

# Run specific test function
docker-compose run --rm test uv run pytest backend/tests/test_api.py::test_root_endpoint -v

# Run tests without coverage report
docker-compose run --rm test uv run pytest backend/tests -v --no-cov
```

### Running Tests Locally (Without Docker)

```bash
# From project root
cd backend
uv run pytest tests -v --cov=backend --cov-report=term-missing
```

## Test Files

### `test_api.py` - API Endpoint Tests

Tests FastAPI endpoints to ensure correct HTTP responses and data structures.

**Tests:**
- `test_root_endpoint()` - Validates root endpoint returns 200 OK
- `test_courses_endpoint()` - Checks `/api/courses` returns course statistics
- `test_query_endpoint_validation()` - Ensures query endpoint validates required fields
- `test_query_endpoint_structure()` - Verifies query endpoint returns correct response structure

**What it tests:**
- HTTP status codes
- Response data structures
- Request validation
- API contract compliance

### `test_document_processor.py` - Document Processing Tests

Tests the document processing pipeline that parses course documents and creates text chunks.

**Tests:**
- `test_chunk_text()` - Validates text chunking with sentence-based splitting
- `test_process_course_document()` - Tests full document parsing from file
- `test_chunk_with_overlap()` - Ensures chunks are created with proper overlap
- `test_empty_document()` - Tests handling of minimal course documents

**What it tests:**
- Course metadata extraction (title, instructor, link)
- Lesson parsing (lesson numbers, titles, links)
- Text chunking algorithm
- File reading and encoding handling

### `test_models.py` - Data Model Tests

Tests Pydantic data models for correct structure and validation.

**Tests:**
- `test_lesson_model()` - Validates Lesson model creation
- `test_course_model()` - Tests Course model with lessons
- `test_course_chunk_model()` - Validates CourseChunk model
- `test_course_with_multiple_lessons()` - Tests Course with multiple lessons

**What it tests:**
- Model field types
- Model instantiation
- Data validation
- Model relationships

### `test_session_manager.py` - Session Management Tests

Tests conversation session management and message history.

**Tests:**
- `test_create_session()` - Validates session creation
- `test_add_message()` - Tests adding messages to sessions
- `test_max_history_limit()` - Ensures history is limited to max_history
- `test_get_conversation_history()` - Tests formatted conversation history
- `test_invalid_session()` - Tests handling of invalid session IDs

**What it tests:**
- Session creation and ID generation
- Message storage
- History limiting (keeps last N exchanges)
- Conversation formatting
- Edge case handling

## Test Fixtures

Defined in `conftest.py`, these fixtures are automatically available to all tests:

### `test_client`
FastAPI test client with mocked RAG system.

```python
def test_example(test_client):
    response = test_client.get("/api/courses")
    assert response.status_code == 200
```

### `mock_anthropic_client`
Mock Anthropic API client to avoid real API calls.

```python
def test_with_mock_ai(mock_anthropic_client):
    # Use mock_anthropic_client instead of real API
    pass
```

### `processor`
DocumentProcessor instance with standard configuration (800 char chunks, 100 char overlap).

```python
def test_document_processing(processor):
    chunks = processor.chunk_text("Some text here.")
    assert len(chunks) > 0
```

### `sample_course_document`
Sample course document string for testing document parsing.

```python
def test_parsing(processor, sample_course_document, tmp_path):
    test_file = tmp_path / "course.txt"
    test_file.write_text(sample_course_document)
    course, chunks = processor.process_course_document(str(test_file))
    assert course.title == "Introduction to Python"
```

### `sample_query`
Sample user query: "What is Python?"

### `sample_session_id`
Sample session ID: "test-session-123"

### `session_manager`
SessionManager instance with max_history=2.

```python
def test_sessions(session_manager):
    session_id = session_manager.create_session()
    session_manager.add_message(session_id, "user", "Hello")
```

## Writing New Tests

### Test File Structure

```python
"""Tests for [component name]."""
import pytest
from backend.your_module import YourClass


@pytest.fixture
def your_fixture():
    """Create a test instance."""
    return YourClass()


def test_your_feature(your_fixture):
    """Test description of what is being tested."""
    # Arrange
    input_data = "test data"

    # Act
    result = your_fixture.process(input_data)

    # Assert
    assert result == expected_output
```

### Best Practices

1. **Use descriptive test names**: `test_chunk_text_handles_long_documents()`
2. **One assertion per concept**: Test one thing at a time
3. **Use fixtures**: Reuse common setup code
4. **Test edge cases**: Empty inputs, null values, boundary conditions
5. **Mock external dependencies**: API calls, databases, file I/O
6. **Keep tests fast**: Avoid real network calls or slow operations

### Example: Adding a New Test

```python
# In test_document_processor.py

def test_chunk_text_preserves_sentences(processor):
    """Test that chunking doesn't break mid-sentence."""
    text = "First sentence. Second sentence. Third sentence."
    chunks = processor.chunk_text(text)

    # Verify no chunk ends mid-word
    for chunk in chunks:
        assert not chunk.endswith(" and")
        assert chunk.endswith((".", "!", "?"))
```

## Test Environment

The test service runs in an isolated Docker container with:
- **Separate ChromaDB instance**: `./backend/chroma_db_test`
- **Environment variable**: `TESTING=true`
- **Python path**: `/app` added to PYTHONPATH
- **Hot reload**: Code changes reflect immediately

## Coverage Reports

### Viewing Coverage

Coverage is displayed after each test run:

```
Name                                       Stmts   Miss  Cover   Missing
------------------------------------------------------------------------
backend/document_processor.py                133     13    90%   18-21, 86-89
backend/session_manager.py                    43      6    86%   39-40, 51, 55
backend/models.py                             22      0   100%
```

### Improving Coverage

To add coverage for untested code:

1. Identify missing lines from coverage report
2. Write tests targeting those lines
3. Re-run tests to verify coverage increase

Example:
```bash
# Check which lines aren't covered
docker-compose run --rm test

# Look for "Missing" column to find untested code
# Write tests for those lines
# Run again to verify
```

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: docker-compose run --rm test
```

## Debugging Tests

### Running Tests with Print Statements

```bash
# Use -s flag to show print output
docker-compose run --rm test uv run pytest backend/tests/test_api.py -s -v
```

### Running a Single Test with Debug Output

```bash
docker-compose run --rm test uv run pytest backend/tests/test_api.py::test_root_endpoint -s -vv
```

### Using pytest.set_trace()

```python
def test_debug_example(processor):
    import pdb; pdb.set_trace()  # Debugger will pause here
    result = processor.chunk_text("Test")
```

## Common Issues

### Import Errors

**Problem**: `ModuleNotFoundError: No module named 'backend'`

**Solution**: Ensure PYTHONPATH is set:
```bash
export PYTHONPATH=/app
# Or use docker-compose which sets this automatically
docker-compose run --rm test
```

### ChromaDB Conflicts

**Problem**: Tests fail due to ChromaDB locks

**Solution**: Tests use separate ChromaDB directory (`chroma_db_test`):
```bash
# Clean test database
rm -rf backend/chroma_db_test
```

### Fixture Not Found

**Problem**: `fixture 'my_fixture' not found`

**Solution**:
1. Check fixture is defined in `conftest.py` or same file
2. Verify fixture name spelling
3. Ensure `@pytest.fixture` decorator is present

## Test Configuration

### pyproject.toml

Pytest configuration in project root:

```toml
[tool.pytest.ini_options]
testpaths = ["backend/tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
```

### Docker Compose Test Service

```yaml
test:
  build:
    context: .
    dockerfile: Dockerfile
  container_name: rag-chatbot-test
  working_dir: /app
  environment:
    - TESTING=true
    - PYTHONPATH=/app
  command: uv run pytest backend/tests -v --cov=backend --cov-report=term-missing
```

## Advanced Usage

### Running Tests with Different Markers

Mark tests for selective running:

```python
@pytest.mark.slow
def test_large_document_processing(processor):
    # Time-consuming test
    pass

@pytest.mark.integration
def test_full_rag_pipeline():
    # Integration test
    pass
```

Run marked tests:
```bash
# Run only slow tests
docker-compose run --rm test uv run pytest -m slow

# Skip slow tests
docker-compose run --rm test uv run pytest -m "not slow"
```

### Parallel Test Execution

```bash
# Install pytest-xdist
uv add --dev pytest-xdist

# Run tests in parallel
docker-compose run --rm test uv run pytest -n auto
```

### HTML Coverage Reports

```bash
# Generate HTML coverage report
docker-compose run --rm test uv run pytest --cov=backend --cov-report=html

# View in browser (run locally)
open backend/htmlcov/index.html
```

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure all tests pass
3. Maintain >80% coverage for new code
4. Update this README if adding new test patterns

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing Guide](https://fastapi.tiangolo.com/tutorial/testing/)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)
- [Pydantic Testing](https://docs.pydantic.dev/latest/concepts/testing/)

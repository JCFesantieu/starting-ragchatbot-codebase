"""Pytest configuration and fixtures for testing."""
import os
import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

# Set testing environment variable
os.environ["TESTING"] = "true"


@pytest.fixture
def mock_anthropic_client():
    """Mock Anthropic client for testing without API calls."""
    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.content = [MagicMock(text="This is a test response")]
    mock_response.stop_reason = "end_turn"
    mock_client.messages.create.return_value = mock_response
    return mock_client


@pytest.fixture
def test_client(monkeypatch):
    """Create a test client for the FastAPI app."""
    import os
    # Set environment to prevent ChromaDB initialization
    monkeypatch.setenv("TESTING", "true")

    # Create a minimal test app with mocked RAG system
    from fastapi import FastAPI
    from fastapi.testclient import TestClient
    from pydantic import BaseModel
    from typing import List, Optional
    from unittest.mock import MagicMock

    # Define response models
    class QueryRequest(BaseModel):
        query: str
        session_id: Optional[str] = None

    class QueryResponse(BaseModel):
        answer: str
        sources: List[str]
        session_id: str

    class CourseStats(BaseModel):
        total_courses: int
        course_titles: List[str]

    test_app = FastAPI(title="Test App")

    # Mock RAG system
    mock_rag_system = MagicMock()
    mock_rag_system.query.return_value = ("Test answer", ["Test source"])
    mock_rag_system.vector_store.get_course_count.return_value = 0
    mock_rag_system.vector_store.get_course_titles.return_value = []
    mock_rag_system.session_manager.create_session.return_value = "test-session-123"

    @test_app.get("/")
    def root():
        return {"message": "test"}

    @test_app.get("/api/courses", response_model=CourseStats)
    def get_courses():
        return CourseStats(
            total_courses=mock_rag_system.vector_store.get_course_count(),
            course_titles=mock_rag_system.vector_store.get_course_titles()
        )

    @test_app.post("/api/query", response_model=QueryResponse)
    async def query(request: QueryRequest):
        answer, sources = mock_rag_system.query(request.query, request.session_id)
        session_id = request.session_id if request.session_id else mock_rag_system.session_manager.create_session()
        return QueryResponse(answer=answer, sources=sources, session_id=session_id)

    return TestClient(test_app)


@pytest.fixture
def sample_course_document():
    """Sample course document for testing."""
    return """Course Title: Introduction to Python
Course Link: https://example.com/python-intro
Course Instructor: John Doe

Lesson 0: Getting Started
Lesson Link: https://example.com/python-intro/lesson-0
Welcome to Python! This lesson covers the basics of Python programming.
Python is a high-level programming language that is easy to learn.

Lesson 1: Variables and Data Types
Lesson Link: https://example.com/python-intro/lesson-1
In this lesson, we'll learn about variables and different data types in Python.
Variables are used to store data values.
"""


@pytest.fixture
def sample_query():
    """Sample user query for testing."""
    return "What is Python?"


@pytest.fixture
def sample_session_id():
    """Sample session ID for testing."""
    return "test-session-123"

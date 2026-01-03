"""Tests for FastAPI endpoints."""
import pytest
from fastapi.testclient import TestClient


def test_root_endpoint(test_client):
    """Test the root endpoint returns success."""
    response = test_client.get("/")
    assert response.status_code == 200


def test_courses_endpoint(test_client):
    """Test the /api/courses endpoint."""
    response = test_client.get("/api/courses")
    assert response.status_code == 200
    data = response.json()
    assert "total_courses" in data
    assert "course_titles" in data
    assert isinstance(data["total_courses"], int)
    assert isinstance(data["course_titles"], list)


@pytest.mark.asyncio
async def test_query_endpoint_validation(test_client):
    """Test query endpoint validates required fields."""
    # Test missing query field
    response = test_client.post("/api/query", json={})
    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_query_endpoint_structure(test_client):
    """Test query endpoint returns correct structure."""
    response = test_client.post(
        "/api/query",
        json={"query": "What is Python?", "session_id": "test-123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert "sources" in data
    assert "session_id" in data
    assert isinstance(data["sources"], list)

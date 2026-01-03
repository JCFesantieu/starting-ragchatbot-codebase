"""Tests for session manager."""
import pytest
from backend.session_manager import SessionManager, Message


@pytest.fixture
def session_manager():
    """Create a SessionManager instance."""
    return SessionManager(max_history=2)


def test_create_session(session_manager):
    """Test session creation."""
    session_id = session_manager.create_session()
    assert isinstance(session_id, str)
    assert len(session_id) > 0


def test_add_message(session_manager, sample_session_id):
    """Test adding messages to session."""
    session_manager.add_message(sample_session_id, "user", "Hello")
    session_manager.add_message(sample_session_id, "assistant", "Hi there")

    history = session_manager.get_messages(sample_session_id)
    assert len(history) == 2
    assert history[0].role == "user"
    assert history[0].content == "Hello"
    assert history[1].role == "assistant"


def test_max_history_limit(session_manager):
    """Test that history is limited to max_history."""
    session_id = session_manager.create_session()

    # Add more messages than max_history (max_history=2 means 4 messages total)
    for i in range(10):
        session_manager.add_message(session_id, "user", f"Message {i}")
        session_manager.add_message(session_id, "assistant", f"Response {i}")

    messages = session_manager.get_messages(session_id)
    # Should keep only max_history * 2 messages (2 exchanges = 4 messages)
    assert len(messages) <= 4


def test_get_conversation_history(session_manager):
    """Test formatted conversation history."""
    session_id = session_manager.create_session()
    session_manager.add_message(session_id, "user", "What is Python?")
    session_manager.add_message(session_id, "assistant", "Python is a programming language.")

    history = session_manager.get_conversation_history(session_id)
    assert "What is Python?" in history
    assert "Python is a programming language" in history


def test_invalid_session(session_manager):
    """Test handling of invalid session ID."""
    messages = session_manager.get_messages("invalid-session-id")
    assert len(messages) == 0

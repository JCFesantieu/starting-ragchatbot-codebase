"""Tests for document processor."""
import pytest
from backend.document_processor import DocumentProcessor
from backend.models import Course


@pytest.fixture
def processor():
    """Create a DocumentProcessor instance."""
    return DocumentProcessor(chunk_size=800, chunk_overlap=100)


def test_chunk_text(processor):
    """Test text chunking functionality."""
    text = "This is a test sentence. " * 100  # Create long text
    chunks = processor.chunk_text(text)

    assert len(chunks) > 0
    assert all(isinstance(chunk, str) for chunk in chunks)


def test_process_course_document(processor, sample_course_document, tmp_path):
    """Test course document processing from file."""
    # Write sample content to a temp file
    test_file = tmp_path / "test_course.txt"
    test_file.write_text(sample_course_document)

    course, chunks = processor.process_course_document(str(test_file))

    assert isinstance(course, Course)
    assert course.title == "Introduction to Python"
    assert course.course_link == "https://example.com/python-intro"
    assert course.instructor == "John Doe"
    assert len(course.lessons) == 2
    assert course.lessons[0].lesson_number == 0
    assert course.lessons[0].title == "Getting Started"
    assert course.lessons[1].lesson_number == 1
    assert len(chunks) > 0


def test_chunk_with_overlap(processor):
    """Test that chunks have proper overlap."""
    text = "Sentence one. Sentence two. Sentence three. Sentence four. Sentence five."
    chunks = processor.chunk_text(text)

    # Verify chunks are created
    assert len(chunks) >= 1
    for chunk in chunks:
        assert len(chunk) > 0
        assert isinstance(chunk, str)


def test_empty_document(processor, tmp_path):
    """Test handling of empty or minimal document."""
    # Test with minimal valid course document
    minimal_doc = """Course Title: Test
Course Link: http://test.com
Course Instructor: Test

Lesson 0: Introduction
Test content."""
    test_file = tmp_path / "minimal.txt"
    test_file.write_text(minimal_doc)

    course, chunks = processor.process_course_document(str(test_file))
    assert course.title == "Test"
    assert len(course.lessons) == 1

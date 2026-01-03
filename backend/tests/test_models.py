"""Tests for data models."""
import pytest
from backend.models import Course, Lesson, CourseChunk


def test_lesson_model():
    """Test Lesson model creation."""
    lesson = Lesson(
        lesson_number=1,
        title="Introduction",
        lesson_link="https://example.com/lesson1"
    )
    assert lesson.lesson_number == 1
    assert lesson.title == "Introduction"
    assert lesson.lesson_link == "https://example.com/lesson1"


def test_course_model():
    """Test Course model creation."""
    lesson = Lesson(lesson_number=0, title="Intro")
    course = Course(
        title="Python 101",
        course_link="https://example.com",
        instructor="John Doe",
        lessons=[lesson]
    )
    assert course.title == "Python 101"
    assert len(course.lessons) == 1
    assert course.instructor == "John Doe"


def test_course_chunk_model():
    """Test CourseChunk model creation."""
    chunk = CourseChunk(
        content="This is test content",
        course_title="Python 101",
        lesson_number=1,
        chunk_index=0
    )
    assert chunk.content == "This is test content"
    assert chunk.course_title == "Python 101"
    assert chunk.lesson_number == 1
    assert chunk.chunk_index == 0


def test_course_with_multiple_lessons():
    """Test Course with multiple lessons."""
    lessons = [
        Lesson(lesson_number=0, title="Intro"),
        Lesson(lesson_number=1, title="Advanced"),
        Lesson(lesson_number=2, title="Expert")
    ]
    course = Course(
        title="Python Course",
        course_link="https://example.com",
        instructor="Jane Doe",
        lessons=lessons
    )
    assert len(course.lessons) == 3
    assert course.lessons[1].title == "Advanced"

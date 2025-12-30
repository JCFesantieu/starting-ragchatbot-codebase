from typing import List, Dict, Optional
from pydantic import BaseModel

class Lesson(BaseModel):
    """Represents a lesson within a course"""
    lesson_number: int  # Sequential lesson number (1, 2, 3, etc.)
    title: str         # Lesson title
    lesson_link: Optional[str] = None  # URL link to the lesson

class Course(BaseModel):
    """Represents a complete course with its lessons"""
    title: str                 # Full course title (used as unique identifier)
    course_link: Optional[str] = None  # URL link to the course
    instructor: Optional[str] = None  # Course instructor name (optional metadata)
    lessons: List[Lesson] = [] # List of lessons in this course

class CourseChunk(BaseModel):
    """Represents a text chunk from a course for vector storage"""
    content: str                        # The actual text content
    course_title: str                   # Which course this chunk belongs to
    lesson_number: Optional[int] = None # Which lesson this chunk is from
    chunk_index: int                    # Position of this chunk in the document

class SourceReference(BaseModel):
    """Represents a source reference with optional links"""
    display: str                          # Human-readable label: "Course X - Lesson Y"
    course_title: str                     # Course title for filtering/grouping
    lesson_number: Optional[int] = None   # Lesson number if available
    course_link: Optional[str] = None     # URL to course homepage
    lesson_link: Optional[str] = None     # URL to specific lesson
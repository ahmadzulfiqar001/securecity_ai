"""
Shared pytest fixtures for cv_engine tests.

Unlike ai_engine's test suite, these tests exercise detector classes
directly (YOLO output filtering, classical HSV/motion heuristics, track
history) rather than the FastAPI app — so no MongoDB/Redis connection is
required to run them.
"""

from __future__ import annotations

import sys
from pathlib import Path

# Make backend/shared/ (the Firebase auth module shared with ai_engine)
# importable when pytest's cwd is backend/cv_engine/ — mirrors how Docker
# already puts both app/ and shared/ on PYTHONPATH at the same level (see
# backend/cv_engine/Dockerfile).
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

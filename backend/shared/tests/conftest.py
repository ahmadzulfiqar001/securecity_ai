"""
Shared pytest fixtures for backend/shared's own tests.

Mirrors the sys.path fix in ai_engine/cv_engine's conftest.py: `shared` is
a sibling of this tests/ dir's grandparent, not an installed package, so
backend/ needs to be on sys.path for `from shared.firebase_auth import
...` to resolve.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

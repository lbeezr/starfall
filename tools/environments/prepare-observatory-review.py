#!/usr/bin/env python3
"""Snapshot production source for isolated, source-bound Observatory verification."""
from pathlib import Path
from export_lab import export_current_tree

root = Path(__file__).resolve().parents[2]
print(export_current_tree(root, 'starfall-observatory-review-'))

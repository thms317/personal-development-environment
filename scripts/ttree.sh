#!/bin/bash

# ttree - A wrapper for the 'tree' command with predefined ignore patterns
# This script runs the tree command with specified ignore patterns from any directory

echo "Generating project tree..."
tree -I '.venv|__pycache__|archive|scratch|.databricks|.ruff_cache|.mypy_cache|.pytest_cache|.git|htmlcov|site|dist|.DS_Store|fixtures' -a
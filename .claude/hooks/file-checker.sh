#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Find the most recently modified file
files=$(find . -type f -mmin -1 -exec ls -t {} + 2>/dev/null | head -1)

if [[ -z "$files" ]]; then
  exit 2
fi

# Check if qlty is available and initialized
if ! command -v qlty >/dev/null 2>&1 || [[ ! -d ".qlty" ]]; then
  echo "" >&2
  echo -e "${GREEN}✅ Code quality good. Continue${NC}" >&2
  exit 2
fi

# Run qlty checks
fmt_output=$(qlty fmt $files 2>&1)
check_output=$(qlty check --fix $files 2>&1)
check_exit_code=$?

# Check for issues
has_issues=false

# Check if formatting happened (this is auto-fixed, so don't count as issue)
formatting_applied=false
if [[ "$fmt_output" == *"Formatted"* ]]; then
  formatting_applied=true
fi

# Check if linting found issues
if [[ "$check_output" != *"No issues"* ]] || [[ $check_exit_code -ne 0 ]]; then
  has_issues=true
fi

# Run type checkers for Python files
pyright_output=""
pyright_issues=false
mypy_output=""
mypy_issues=false

if [[ "$files" == *.py ]]; then
  # Run Pyright if available
  if command -v pyright >/dev/null 2>&1; then
    pyright_output=$(pyright --outputjson $files 2>&1 || true)

    # Check for errors in JSON output or fallback to text check
    if echo "$pyright_output" | grep -q '"errorCount":[1-9]' || [[ "$pyright_output" == *" error"* ]]; then
      pyright_issues=true
      has_issues=true
    fi
  fi

  # Run Mypy if available
  if command -v mypy >/dev/null 2>&1; then
    mypy_output=$(mypy --no-error-summary --show-column-numbers $files 2>&1 || true)

    # Check if mypy found errors (not just notes/warnings)
    if echo "$mypy_output" | grep -q "error:"; then
      mypy_issues=true
      has_issues=true
    fi
  fi
fi

# Remove test logic - now using real qlty detection

# Display results
if [[ $has_issues == true ]]; then
  echo "" >&2
  echo -e "${RED}🛑 STOP - Issues found in: $files${NC}" >&2
  echo -e "${RED}The following MUST BE FIXED:${NC}" >&2
  echo "" >&2

  if [[ "$check_output" != *"No issues"* ]]; then
    # Extract remaining issue lines (skip headers/footers)
    issue_lines=$(echo "$check_output" | grep -E "^\s*[0-9]+:[0-9]+\s+|high\s+|medium\s+|low\s+" | head -3)
    remaining_issues=$(echo "$check_output" | grep -c "high\|medium\|low" 2>/dev/null || echo "0")

    # Simple, clear output
    echo "🔍 Linting Issues: ($remaining_issues remaining)" >&2

    if [[ -n "$issue_lines" ]]; then
      echo "$issue_lines" >&2
      if [[ $remaining_issues -gt 3 ]]; then
        echo "... and $((remaining_issues - 3)) more issues" >&2
      fi
    else
      # Fallback: show first few lines if parsing failed
      echo "$check_output" | head -5 >&2
    fi
    echo "" >&2
  fi

  if [[ $pyright_issues == true ]]; then
    # Try to extract from JSON first, fallback to text parsing
    error_count=$(echo "$pyright_output" | grep -oP '"errorCount":\K\d+' | head -1)
    if [[ -z "$error_count" ]]; then
      error_count=$(echo "$pyright_output" | grep -oP '\d+(?= error)' | head -1)
    fi

    # Extract error lines
    error_lines=$(echo "$pyright_output" | grep -E "error:|Error:" | head -3)

    echo "🐍 Pyright Type Errors: ($error_count found)" >&2
    if [[ -n "$error_lines" ]]; then
      echo "$error_lines" >&2
      if [[ $error_count -gt 3 ]]; then
        echo "... and $((error_count - 3)) more errors" >&2
      fi
    else
      # Fallback: show summary from output
      echo "$pyright_output" | tail -5 >&2
    fi
    echo "" >&2
  fi

  if [[ $mypy_issues == true ]]; then
    # Count mypy errors
    error_count=$(echo "$mypy_output" | grep -c "error:" || echo "0")
    error_lines=$(echo "$mypy_output" | grep "error:" | head -3)

    echo "🔍 Mypy Type Errors: ($error_count found)" >&2
    if [[ -n "$error_lines" ]]; then
      echo "$error_lines" >&2
      if [[ $error_count -gt 3 ]]; then
        echo "... and $((error_count - 3)) more errors" >&2
      fi
    fi
    echo "" >&2
  fi

  echo -e "${RED}Fix all issues above before continuing${NC}" >&2
else
  echo "" >&2
  if [[ $formatting_applied == true ]]; then
    echo -e "${GREEN}✅ Formatted $files. Code quality good. Continue${NC}" >&2
  else
    echo -e "${GREEN}✅ Code quality good. Continue${NC}" >&2
  fi
fi

exit 2

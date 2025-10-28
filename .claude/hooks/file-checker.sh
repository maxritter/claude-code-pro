#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Find recently modified files (last minute)
files=$(find . -maxdepth 6 -type f -mmin -1 \
  -not -path "*/__pycache__/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/.venv/*" \
  -not -path "*/.next/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.mypy_cache/*" \
  -not -path "*/.pytest_cache/*" \
  -not -path "*/.ruff_cache/*" \
  -not -path "*/.qlty/*" \
  -not -path "*/coverage/*" \
  -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2)

# Exit early if no files found
if [[ -z $files ]]; then
  exit 0
fi

# Set tool paths
QLTY_BIN="${HOME}/.qlty/bin/qlty"
PYRIGHT_BIN="${HOME}/.local/bin/pyright"

# Check if QLTY is available
if [[ ! -x "$QLTY_BIN" ]] || [[ ! -f ".qlty/qlty.toml" ]]; then
  exit 0
fi

# Run QLTY format
"$QLTY_BIN" fmt "$files" >/dev/null 2>&1

# Run QLTY check
"$QLTY_BIN" check "$files" >/dev/null 2>&1

# Run final QLTY check to get status
qlty_output=$("$QLTY_BIN" check "$files" 2>&1)
qlty_exit=$?

# For Python files, also run pyright
pyright_output=""
pyright_exit=0

if [[ $files == *.py ]]; then
  if [[ -x "$PYRIGHT_BIN" ]]; then
    pyright_output=$("$PYRIGHT_BIN" "$files" 2>&1)
    pyright_exit=$?

    # Check if output contains actual errors
    if ! echo "$pyright_output" | grep -q " error:"; then
      pyright_exit=0
    fi
  fi
fi

# Determine if there are issues
has_issues=false
error_sections=""

if [[ $qlty_exit -ne 0 ]] || echo "$qlty_output" | grep -qE "error|warning|✗"; then
  has_issues=true
  error_sections+="📋 QLTY Issues:\n\n$qlty_output\n\n"
fi

if [[ $pyright_exit -ne 0 ]] && [[ -n "$pyright_output" ]]; then
  has_issues=true
  pyright_errors=$(echo "$pyright_output" | grep -E " error:")
  if [[ -n "$pyright_errors" ]]; then
    error_sections+="🔍 Pyright Type Errors:\n\n$pyright_errors\n\n"
  fi
fi

# Report results
if [[ $has_issues == true ]]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "${RED}🛑 Quality Issues in: $files${NC}" >&2
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo "" >&2
  echo -e "$error_sections" >&2
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "${RED}Fix all issues above before continuing${NC}" >&2
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  exit 1
fi

# Success
echo -e "${GREEN}✅ Quality checks passed for $files${NC}" >&2
exit 0

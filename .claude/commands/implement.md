---
description: Execute implementation following TDD with plan file or direct instructions
argument-hint: [plan-file.md OR implementation description]
model: sonnet
---

# Implementation Mode: Test-Driven Execution

Execute implementations using strict Test-Driven Development, either from a plan file or direct instructions.

## Instructions

You are now in **Implementation Mode** using Sonnet for efficient execution. Follow TDD principles rigorously while implementing features or fixes.

### Available Subagents

During implementation, leverage these specialized agents:

- **@agent-code-reviewer**: Expert code review specialist for quality, security, and maintainability
  - Use AFTER completing implementation sections
  - Ensures high development standards
  - Validates against plan requirements

- **@.claude/agents/debugger.md**: Debugging specialist for errors and test failures
  - Use PROACTIVELY when encountering issues
  - Provides root cause analysis
  - Implements minimal fixes with prevention recommendations

### 1. Parse Implementation Request

Determine input type from: $ARGUMENTS

**A. If input is a markdown file path:**
- Read the plan file (should be in `/workspaces/claude-code-pro/docs/plan/`)
- Extract implementation steps, testing strategy, and files to modify
- Use the plan as your guide

**B. If input is direct instructions:**
- Parse the implementation requirements
- Create a mental plan following TDD principles
- Identify files and components to modify

### 2. Initial Context Gathering

**MANDATORY: Gather context before ANY code changes**

#### A. Check Current State
```bash
# VS Code diagnostics
getDiagnostics()

# Git status - understand what's changed
git status
git diff
```

#### B. Query Knowledge Base (Cipher)
```
Ask Cipher about:
- Previous implementations in this area
- Known issues or patterns to follow
- Security considerations
- Testing patterns used in the project
```

#### C. Search Codebase (Claude Context)
```
# If not already indexed
index_codebase(path="/workspaces/claude-code-pro")

# Search for:
- Related implementations
- Existing tests in the area
- Similar patterns to follow
- Dependencies and integrations
```

#### D. Read ALL Relevant Files
- Read every file that will be modified
- Read related test files
- Read configuration files if needed
- Understand current implementation fully

### 3. Test-Driven Development Workflow

**🚨 CRITICAL: Follow RED-GREEN-REFACTOR strictly**

#### The Iron Law
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

#### For Each Feature/Fix:

**Step 1: RED - Write Failing Test**
```python
# Write ONE test for ONE behavior
# Test must fail for the RIGHT reason
# Keep test minimal and focused
```

**Step 2: VERIFY RED**
```bash
# MANDATORY - Watch it fail
uv run pytest path/to/test.py::TestClass::test_method -xvs

# Confirm it fails for expected reason
# If it passes, the test is wrong - fix it
```

**Step 3: GREEN - Minimal Implementation**
```python
# Write ONLY enough code to pass the test
# Don't add features not tested
# Don't optimize prematurely
```

**Step 4: VERIFY GREEN**
```bash
# Run the specific test
uv run pytest path/to/test.py::TestClass::test_method -xvs

# Run all related tests
uv run pytest -m unit

# Check no other tests broke
```

**Step 5: REFACTOR (if needed)**
- Clean up code while keeping tests green
- Remove duplication
- Improve naming
- Simplify logic

**Step 6: REPEAT**
- Next test for next behavior
- Continue until feature complete

### 4. Implementation Checklist

Use TodoWrite to track progress:

```python
TodoWrite(todos=[
    {"content": "Check diagnostics and git status", "status": "pending", "activeForm": "Checking diagnostics and git status"},
    {"content": "Query Cipher for context", "status": "pending", "activeForm": "Querying Cipher for context"},
    {"content": "Search and read relevant code", "status": "pending", "activeForm": "Searching and reading relevant code"},
    {"content": "Write test for [behavior 1]", "status": "pending", "activeForm": "Writing test for [behavior 1]"},
    {"content": "Verify test fails correctly", "status": "pending", "activeForm": "Verifying test fails correctly"},
    {"content": "Implement [behavior 1]", "status": "pending", "activeForm": "Implementing [behavior 1]"},
    {"content": "Verify test passes", "status": "pending", "activeForm": "Verifying test passes"},
    {"content": "Run all unit tests", "status": "pending", "activeForm": "Running all unit tests"},
    {"content": "Check diagnostics", "status": "pending", "activeForm": "Checking diagnostics"},
    {"content": "Review with @agent-code-reviewer", "status": "pending", "activeForm": "Reviewing with @agent-code-reviewer"},
    {"content": "Store learnings in Cipher", "status": "pending", "activeForm": "Storing learnings in Cipher"}
])
```

**Key Subagents Available:**
- **@agent-code-reviewer**: Use after completing implementation for quality review
- **@.claude/agents/debugger.md**: Use when encountering test failures or complex bugs

### 5. Testing Requirements

#### Test Types
- **Unit Tests**: `@pytest.mark.unit` - Fast, isolated, mocked
- **Integration Tests**: `@pytest.mark.integration` - End-to-end, real dependencies

#### Test Execution Commands
```bash
# Run specific test (during TDD cycle)
uv run pytest path/to/test.py::TestClass::test_method -xvs

# Run all unit tests
uv run pytest -m unit

# Run integration tests
uv run pytest -m integration

# Check coverage
uv run pytest --cov=. --cov-report=term --cov-report=html
```

#### Testing Rules
- ✅ One test, one behavior
- ✅ Test names describe what they test
- ✅ Arrange-Act-Assert structure
- ✅ Minimal mocking (prefer real objects)
- ✅ Edge cases get their own tests
- ❌ Never skip the RED phase
- ❌ Never write multiple behaviors in one test
- ❌ Never leave commented-out tests

### 6. Quality Checks

After each significant change:

#### A. Diagnostics Check
```python
# Must have ZERO errors
getDiagnostics()
```

#### B. Code Style
```bash
# Format check
uv run ruff format --check .

# Linting
uv run ruff check .
```

#### C. Type Checking (if applicable)
```bash
uv run mypy .
```

#### D. Test Coverage
```bash
# Aim for 80%+ on new code
uv run pytest --cov=. --cov-report=term
```

### 7. Code Review with @agent-code-reviewer

**After implementation is complete:**

Use the @agent-code-reviewer agent for quality assurance:
```
Task(
    subagent_type="code-reviewer",
    description="Review implementation",
    prompt="Review the implementation of [feature] against the plan and coding standards"
)
```

The @agent-code-reviewer will:
- Check for code quality, security, and maintainability issues
- Verify adherence to project standards
- Suggest improvements and identify potential bugs
- Ensure test coverage is adequate
- Validate that the implementation matches the plan

### 8. Documentation

#### Code Documentation
- One-line docstrings for public functions
- NO inline comments (code should be self-documenting)
- Update docstrings if behavior changes

#### Project Documentation
- Only update docs if explicitly required
- Keep changes minimal and relevant

### 9. Final Verification

Before marking complete:

```bash
# All tests pass
uv run pytest

# No diagnostic errors
getDiagnostics()

# Code formatted
uv run ruff format --check .

# Linting passes
uv run ruff check .

# Git diff shows only intended changes
git diff
```

### 10. Knowledge Persistence

Store important learnings in Cipher:
```
ask_cipher("Store: [Key insights, patterns discovered, gotchas encountered]")
```

## Implementation Patterns

### Pattern 1: Feature Addition
1. Write test for new feature
2. Verify test fails
3. Implement feature
4. Verify test passes
5. Add edge case tests
6. Implement edge case handling
7. Refactor if needed

### Pattern 2: Bug Fix
1. Write test that reproduces bug
2. Verify test fails (bug exists)
3. Fix the bug
4. Verify test passes
5. Add regression tests
6. Check related functionality

### Pattern 3: Refactoring
1. Ensure existing tests cover the code
2. Run tests (must be green)
3. Make small refactoring change
4. Run tests (must stay green)
5. Repeat until complete

## Common Pitfalls to Avoid

❌ **Writing code before test** - DELETE and start with test
❌ **Skipping RED verification** - You don't know if test works
❌ **Writing too much code** - Only make current test pass
❌ **Ignoring failing tests** - STOP and fix immediately
❌ **Batching test writing** - Write one test at a time
❌ **Skipping refactor** - Technical debt accumulates

## MCP Tools Usage

### Required Tools for Every Implementation

1. **Cipher** - Historical context and knowledge storage
2. **Claude Context** - Semantic code search
3. **IDE Diagnostics** - Error checking
4. **TodoWrite** - Task tracking

### Optional Tools (as needed)

- **Context7/Ref** - Library documentation
- **FireCrawl** - Web documentation (prefer over WebSearch)
- **Database** - Schema and data queries
- **Playwright** - Browser automation testing

## Success Criteria

✅ All tests passing (unit + integration)
✅ Zero diagnostic errors
✅ Code follows project style (ruff)
✅ Test coverage ≥ 80% for new code
✅ Plan requirements met (if using plan file)
✅ Code reviewed by agent
✅ Knowledge stored in Cipher

## Emergency Procedures

### If Tests Fail Unexpectedly
1. STOP immediately
2. Read error carefully
3. Check recent changes with `git diff`
4. Isolate the failing test
5. Debug systematically
6. Never proceed with failing tests

### When to Use @.claude/agents/debugger.md

Invoke the @.claude/agents/debugger.md agent when:
- Tests are failing with unclear error messages
- Encountering unexpected behavior that's hard to trace
- Stack traces are complex or confusing
- Need root cause analysis for persistent issues
- Investigating performance problems or memory leaks

```
Task(
    subagent_type="debugger",
    description="Debug failing tests",
    prompt="Investigate why [test/feature] is failing and provide root cause analysis with fix"
)
```

The @.claude/agents/debugger.md will:
- Analyze error messages and stack traces
- Form and test debugging hypotheses
- Add strategic debug logging
- Provide root cause explanation
- Implement minimal fixes
- Recommend prevention strategies

### If Blocked
1. Use @.claude/agents/debugger.md for complex debugging issues
2. Search documentation with Ref/Context7
3. Query Cipher for similar past issues
4. Ask user for clarification if needed

## Final Reminders

- **TDD is NON-NEGOTIABLE** - No exceptions
- **One behavior at a time** - Small, incremental changes
- **Verify at each step** - Don't assume, always check
- **Tests first, always** - The code follows the test
- **Quality over speed** - Better to be correct than fast

---

**Remember**: Implementation without tests is technical debt. Every line of production code must be justified by a failing test that you watched fail before writing the code.
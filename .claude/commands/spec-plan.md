---
description: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
model: opus
---

# Writing Detailed Implementation Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Workflow Position:** Step 2 of 3 in spec-driven development
- **Previous command (/spec-design):** Brainstorm → Design Document
- **This command (spec-plan):** Design Document → Implementation Plan
- **Next command (/spec-implement):** Implementation Plan → Working Code

**Input location:** `docs/designs/YYYY-MM-DD-<topic>-design.md`
**Output location:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## MCP Tools for This Stage

**Use these MCP servers during planning:**

1. **Cipher** - Store the plan, query for similar implementations
   ```
   ask_cipher("Store this implementation plan for <feature>")
   ask_cipher("How have we implemented similar features?")
   ```

2. **Claude Context** - Find exact file paths, understand codebase structure
   ```
   search_code(path="/workspaces/...", query="existing auth files")
   ```

3. **Ref/Context7** - Get detailed API documentation for implementation
   ```
   ref_search_documentation(query="pytest fixtures documentation")
   get-library-docs(context7CompatibleLibraryID="/pytest-dev/pytest", topic="fixtures")
   ```

4. **Database (if planning DB changes)** - Check current schema
   ```
   execute_sql("SELECT column_name FROM information_schema.columns WHERE table_name='users'")
   ```

5. **FireCrawl (if external research needed)** - Scrape documentation, examples, best practices
   ```
   discover_tools_by_words(words="firecrawl", enable=true)
   // Then use: firecrawl_scrape, firecrawl_search
   ```

**Testing Tools Available:**
- **Newman (Postman CLI)** - For API end-to-end tests (already installed)
- **Playwright** - For browser automation tests (enable during implementation)

**NOT needed during planning:** IDE diagnostics (no code yet)

## Step 0: Load Design Document

**FIRST ACTION:** Read the design document that was passed as an argument or created in /spec-design

```bash
# If provided as argument: /spec-plan docs/designs/2025-01-15-auth-design.md
# Read that specific file
```

If no argument provided, ask: "Which design document should I create a plan from? (Check docs/designs/)"

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use skill spec-implement to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`
- E2E Test (if API): `postman/collections/feature-name.json`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: (IF API) Write E2E test with Newman/Postman**

Create/update Postman collection: `postman/collections/feature-name.json`

```json
{
  "info": {"name": "Feature Name API Tests"},
  "item": [{
    "name": "Test endpoint",
    "request": {
      "method": "POST",
      "url": "{{base_url}}/api/endpoint",
      "body": {...}
    },
    "test": "pm.test('Status is 200', () => pm.response.to.have.status(200));"
  }]
}
```

**Step 6: (IF API) Run Newman E2E test**

Run: `newman run postman/collections/feature-name.json -e postman/environments/dev.json`
Expected: All tests pass

**Step 7: Commit**

```bash
git add tests/path/test.py src/path/file.py postman/collections/feature-name.json
git commit -m "feat: add specific feature with E2E tests"
```
```

## Skills to Reference in Plans

**Reference these skills in implementation steps:**

### Testing Skills (Use in EVERY Task)

- **@testing-test-driven-development** - MANDATORY for ALL code implementation (RED-GREEN-REFACTOR cycle)
- **@testing-test-writing** - When writing any test files, test cases, or test strategies
- **@testing-anti-patterns** - When plan includes mocking, test doubles, or complex test setup
- **@testing-debugging** - When plan includes troubleshooting, bug fixes, or error investigation
- **@testing-final-verification** - At completion checkpoints and before marking tasks complete
- **@testing-code-reviewer** - After completing significant features or logical units of work

### Global Skills (Apply to All Code)

- **@global-coding-style** - For code formatting, naming conventions, file organization
- **@global-commenting** - When documentation or code comments are needed (keep minimal)
- **@global-conventions** - For project structure, dependency management, file organization
- **@global-error-handling** - When implementing error handling, try-catch, exception handling
- **@global-validation** - When implementing input validation, data validation, sanitization

### Backend Skills (Server-Side Code)

- **@backend-api** - For API endpoints, route handlers, REST/GraphQL implementations
- **@backend-models** - For database models, ORMs, entity definitions, schema classes
- **@backend-queries** - For database queries, repository patterns, data access logic
- **@backend-migrations** - For database schema changes, migration files, version control

### Frontend Skills (Client-Side Code)

- **@frontend-components** - For UI components, React/Vue/Svelte components, reusable elements
- **@frontend-css** - For styling, CSS/SCSS/Tailwind, design system adherence
- **@frontend-accessibility** - For user-facing features, ARIA attributes, keyboard navigation
- **@frontend-responsive** - For responsive layouts, mobile-first design, breakpoints

## Coding Standards to Enforce in Plans

**Every task must follow:**

✅ **TDD Mandatory** - Test first, watch fail, implement, watch pass
✅ **DRY** - Don't repeat yourself
✅ **YAGNI** - You aren't gonna need it (no speculative features)
✅ **Frequent commits** - After each passing test
✅ **Exact file paths** - No ambiguity about where code goes
✅ **Complete code examples** - Never "add validation here"
✅ **Exact verification commands** - With expected output
✅ **One-line docstrings** - For public functions only
✅ **No inline comments** - Code should be self-documenting
✅ **Imports at top** - No scattered imports

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

**Output from this phase:**
- Implementation plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md`
- Plan document committed to git

**Transition to spec-implement:**

Output to user: "Plan complete and saved to `docs/plans/<filename>.md`."

Ask: "Ready to implement the specification tasks?"

When your human partner confirms (any affirmative response):
- Announce: "I'm transitioning to /spec-implement to execute this plan task-by-task."
- **REQUIRED SUB-COMMAND:** Use `/spec-implement docs/plans/YYYY-MM-DD-<feature-name>.md`
- The spec-implement command will load the plan and execute it in batches with checkpoints for review

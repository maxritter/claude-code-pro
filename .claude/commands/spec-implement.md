---
description: Use when partner provides a complete implementation plan to execute - loads plan, reviews critically, executes tasks in batches, reports for review between batches
model: sonnet
---

# Implementing Specification Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Workflow Position:** Step 3 of 3 in spec-driven development
- **Previous command (/spec-design):** Brainstorm → Design Document
- **Previous command (/spec-plan):** Design Document → Implementation Plan
- **This command (spec-implement):** Implementation Plan → Working Code

**Input location:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
**Output:** Working, tested code committed to git

## MCP Tools for This Stage

**Use these MCP servers during implementation:**

1. **IDE Diagnostics (CHECK FIRST & LAST)** - Verify no errors before/after changes
   ```
   getDiagnostics()  // Check all files
   getDiagnostics(uri="file:///path/to/file.py")  // Check specific file
   ```

2. **Cipher** - Query for implementation patterns, store discoveries
   ```
   ask_cipher("How did we implement <similar feature>?")
   ask_cipher("Store: We discovered that <pattern> works well for <use case>")
   ```

3. **Claude Context** - Search codebase for examples, understand existing code
   ```
   search_code(path="/workspaces/...", query="error handling patterns")
   ```

4. **Ref/Context7** - Look up API documentation during implementation
   ```
   ref_search_documentation(query="pytest assert methods")
   get-library-docs(context7CompatibleLibraryID="/pytest-dev/pytest", topic="assertions")
   ```

5. **Database (when needed)** - Check schema, run queries, verify data
   ```
   execute_sql("SELECT * FROM users LIMIT 1")  // Verify structure
   ```

6. **FireCrawl (if external research needed)** - Scrape documentation, API examples during implementation
   ```
   discover_tools_by_words(words="firecrawl", enable=true)
   // Then use: firecrawl_scrape(url="..."), firecrawl_search(query="...")
   ```

7. **Playwright (for UI testing)** - Enable only if implementing browser automation tests
   ```
   discover_tools_by_words(words="playwright browser", enable=true)
   // Then use: browser_navigate, browser_click, browser_snapshot
   ```

## Standard Task Flow (Use for EVERY Task)

1. **Diagnostics** - Check VS Code problems: `getDiagnostics()`
2. **Knowledge** - Query Cipher for cross-session context
3. **Search** - Use Claude Context for semantic code search (if needed)
4. **Research** - Fetch docs via Ref/Context7 (if needed)
5. **Test** - Write failing test FIRST (TDD) - **MANDATORY**
6. **Implement** - Write minimal code to pass
7. **Verify** - Check diagnostics and run tests
8. **E2E Test (IF API)** - Write and run Newman/Postman E2E tests
9. **Commit** - Git commit (user does this, not you)
10. **Store** - Save discoveries in Cipher

## API End-to-End Testing with Newman

**When implementing APIs, ALWAYS add Newman E2E tests:**

1. **Create/update Postman collection** - Store in `postman/collections/`
   ```json
   {
     "info": {"name": "Feature API Tests"},
     "item": [{
       "name": "Test endpoint behavior",
       "request": {
         "method": "POST",
         "url": "{{base_url}}/api/endpoint",
         "header": [{"key": "Content-Type", "value": "application/json"}],
         "body": {"mode": "raw", "raw": "{\"key\": \"value\"}"}
       },
       "event": [{
         "listen": "test",
         "script": {
           "exec": [
             "pm.test('Status is 200', () => pm.response.to.have.status(200));",
             "pm.test('Response has expected structure', () => {",
             "  pm.expect(pm.response.json()).to.have.property('data');",
             "});"
           ]
         }
       }]
     }]
   }
   ```

2. **Run Newman E2E tests**
   ```bash
   newman run postman/collections/feature-name.json -e postman/environments/dev.json
   ```

3. **Verify all tests pass** - Green output, no failures

**Newman is installed and ready to use - no setup needed.**

## TDD Enforcement (NON-NEGOTIABLE)

### The Iron Law
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

### RED-GREEN-REFACTOR Cycle
1. **RED** - Write test for desired behavior
2. **VERIFY FAILURE** - Watch it fail for the right reason
3. **GREEN** - Write minimal code to pass
4. **VERIFY PASS** - Confirm test passes
5. **REFACTOR** - Clean up while keeping green
6. **REPEAT** - Next test for next behavior

**If you write code before test:** STOP. Delete code. Start with test.

## The Process

### Step 1: Load and Review Plan

**FIRST ACTION:** Read the implementation plan that was passed as an argument or created in /spec-plan

```bash
# If provided as argument: /spec-implement docs/plans/2025-01-15-auth-plan.md
# Read that specific file
```

If no argument provided, ask: "Which implementation plan should I execute? (Check docs/plans/)"

**Then:**
1. Read the plan file completely
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite with all tasks and proceed
5. **Run getDiagnostics()** - Ensure clean starting state

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress in TodoWrite
2. **Run getDiagnostics()** before starting
3. Follow Standard Task Flow (above) for EVERY task
4. Follow each step exactly (plan has bite-sized steps)
5. **ENFORCE TDD** - Test first, always
6. Run verifications as specified
7. **Run getDiagnostics()** after implementation
8. Mark as completed in TodoWrite

**Coding Standards (ENFORCE):**

✅ **TDD Mandatory** - Test first, watch fail, implement, watch pass
✅ **Use `uv` for Python packages** - NEVER use pip directly
✅ **One-line docstrings** - For public functions only
✅ **No inline comments** - Code should be self-documenting
✅ **Imports at top** - All imports at file start
✅ **DRY** - Don't repeat yourself
✅ **YAGNI** - No speculative features
✅ **Check diagnostics** - Before and after each task
✅ **No files created unnecessarily** - Prefer editing existing

**Skills Active During Implementation:**

### Testing Skills (Active in EVERY Task)

- **@testing-test-driven-development** - Enforces RED-GREEN-REFACTOR cycle (MANDATORY)
- **@testing-test-writing** - Guides test file creation, test case structure, assertions
- **@testing-anti-patterns** - Prevents mock testing, test pollution, incomplete mocks
- **@testing-debugging** - Systematic 4-phase debugging when issues arise
- **@testing-final-verification** - Evidence-based completion verification
- **@testing-code-reviewer** - Reviews completed work against plan and standards

### Global Skills (Active for All Code)

- **@global-coding-style** - Enforces naming, formatting, organization, DRY principles
- **@global-commenting** - Ensures minimal, self-documenting code (no inline comments)
- **@global-conventions** - Project structure, dependencies, version control practices
- **@global-error-handling** - Error handling patterns, try-catch, exception handling
- **@global-validation** - Input validation, data sanitization, defensive programming

### Backend Skills (Activate for Server-Side Files)

- **@backend-api** - API endpoints, route handlers, controllers, REST/GraphQL
- **@backend-models** - Database models, ORMs, entity classes, schema definitions
- **@backend-queries** - Database queries, repository patterns, data access optimization
- **@backend-migrations** - Database schema changes, migration files, rollback strategies

### Frontend Skills (Activate for Client-Side Files)

- **@frontend-components** - UI components, component composition, props/interfaces
- **@frontend-css** - Styling, CSS/SCSS/Tailwind, design system, utility classes
- **@frontend-accessibility** - ARIA attributes, keyboard navigation, screen readers, WCAG
- **@frontend-responsive** - Responsive layouts, breakpoints, mobile-first design

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete:

**Final Verification Checklist:**

1. **Run getDiagnostics()** - Must be clean (zero errors/warnings)
2. **Run full test suite** - All tests must pass
   ```bash
   uv run pytest  # or project-specific command
   ```
3. **Verify test coverage** - Check that new code is tested
   ```bash
   uv run pytest --cov=. --cov-report=term
   ```
4. **Run Newman E2E tests (IF API)** - All API tests must pass
   ```bash
   newman run postman/collections/feature-name.json -e postman/environments/dev.json
   ```
   Expected: All E2E tests pass, status codes correct, response structure validated
5. **Check code quality** - Run linter/formatter
   ```bash
   uv run ruff check .  # for Python projects
   uv run ruff format .
   ```
6. **Announce:** "I'm using the @testing-final-verification skill to complete this work."
7. **REQUIRED SUB-SKILL:** Use @testing-final-verification skill
8. **Store learnings in Cipher:**
   ```
   ask_cipher("Store: Completed <feature>. Key learnings: <insights>")
   ```

**Evidence Required Before Completion:**
- ✅ Fresh test run output showing all tests pass
- ✅ Diagnostics output showing zero issues
- ✅ Coverage report showing new code is tested
- ✅ Newman E2E test output (if API) showing all endpoints tested
- ✅ Linter output showing code quality standards met

**NO claims of completion without running these commands and showing output.**

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Git Operations - READ ONLY

**CRITICAL:** You NEVER modify git state. User controls all commits.

✅ **Allowed:** `git status`, `git diff`, `git log`, `git show`, `git branch` (list)
❌ **FORBIDDEN:** `git add`, `git commit`, `git push`, `git pull`, `git merge`, `git rebase`, `git checkout`, `git reset`, `git stash`

**When plan says "commit":** Tell user "Ready to commit these changes" and STOP.

## Remember

- **Review plan critically first** - Raise concerns before starting
- **Follow Standard Task Flow** - Diagnostics → Knowledge → Search → Research → Test → Implement → Verify
- **ENFORCE TDD** - Test first, always. No exceptions.
- **Check diagnostics** - Before and after each task
- **Don't skip verifications** - Run all commands, show output
- **Reference skills** - They enforce standards automatically
- **Between batches** - Report and wait for feedback
- **Stop when blocked** - Don't guess, ask for help
- **Store learnings** - Save discoveries in Cipher
- **Use appropriate MCP tools** - IDE, Cipher, Claude Context, Ref, Database as needed
- **Final verification** - Evidence required before completion claims

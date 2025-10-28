---
description: Deep planning for features/fixes with comprehensive codebase analysis
argument-hint: [feature or bug description]
model: opus
---

# Plan Mode: Deep Planning with Comprehensive Analysis

Create a detailed implementation plan for smaller features or bug fixes using deep thinking and comprehensive codebase analysis. For complex features requiring full specification, use Agent-OS spec-driven development instead.

## Instructions

You are now in **Plan Mode** with enhanced analytical capabilities. Your goal is to create a comprehensive, actionable implementation plan by deeply understanding the codebase, relevant patterns, and best practices.

### 1. Parse the Request
- Extract the core feature/bug from: $ARGUMENTS
- Identify scope and complexity
- Determine if this should use `/plan` (smaller changes) or Agent-OS (complex features)
- If Agent-OS is more appropriate, recommend switching to spec-driven development

### 2. Knowledge Discovery Phase

**A. Query Historical Context (Cipher)**
```
Ask Cipher about:
- Past work related to this feature/bug
- Known issues or gotchas in this area
- Architecture patterns used in the project
- Security concerns or best practices
- Previous similar implementations
```

**B. Index and Search Codebase (Claude Context)**
```
1. Index the current codebase: index_codebase(path="/workspaces/claude-code-pro")
2. Search for relevant code:
   - Files related to the feature/bug area
   - Similar implementations or patterns
   - Tests covering related functionality
   - Configuration files that may need updates
3. Identify:
   - Entry points
   - Dependencies
   - Related components
   - Existing tests
```

**C. Research Documentation (Ref/Context7)**
```
1. Search for library documentation if using external libraries
2. Look for API documentation for dependencies
3. Find best practices for the technology stack
4. Research design patterns applicable to the solution
```

**D. Database Context (DBHub if applicable)**
```
- Query database schema for related tables
- Understand data models and relationships
- Identify database constraints or migrations needed
```

### 3. Multi-Dimensional Analysis

Analyze the problem from multiple perspectives:

#### Technical Perspective
- Current implementation details
- Technical constraints and dependencies
- Performance implications
- Security considerations
- Testing requirements
- Maintainability concerns

#### Integration Perspective
- Impact on existing components
- API compatibility
- Data flow changes
- Configuration changes
- Migration requirements

#### User/Business Perspective
- User-facing changes
- Edge cases to handle
- Error scenarios
- Validation requirements
- UX considerations

#### Risk Assessment
- What could go wrong?
- Breaking changes?
- Backward compatibility
- Performance degradation
- Security vulnerabilities

### 4. Solution Design

**A. Read Existing Code**
- Carefully read all relevant files identified in step 2
- Understand current patterns and conventions
- Identify reusable components
- Note technical debt or areas for improvement

**B. Generate Solution Approach**
Consider:
- Primary implementation approach
- Alternative approaches (if any)
- Pros and cons of each
- Recommended approach with rationale

**C. Break Down Implementation**
Create detailed steps:
1. Preparation (setup, dependencies)
2. Core implementation (ordered tasks)
3. Testing (unit + integration)
4. Documentation updates
5. Verification steps

### 5. Create Implementation Plan

Generate a structured plan with:

```markdown
# Implementation Plan: [Feature/Bug Name]

**Date**: [YYYY-MM-DD]
**Type**: [Feature/Bug Fix/Enhancement]
**Complexity**: [Simple/Medium - not for Complex, use Agent-OS]
**Estimated Effort**: [Small/Medium]

## Problem Statement
[Clear description of what needs to be done and why]

## Current State Analysis
[What exists today, based on codebase analysis]

## Historical Context
[Relevant insights from Cipher about past work, known issues, patterns]

## Technical Analysis

### Affected Components
- [Component 1]: [Description and impact]
- [Component 2]: [Description and impact]

### Dependencies
- [Dependency 1]: [Version, usage, considerations]
- [Dependency 2]: [Version, usage, considerations]

### Integration Points
- [Integration 1]: [How it connects, what changes]
- [Integration 2]: [How it connects, what changes]

## Solution Design

### Recommended Approach
[Detailed explanation of the chosen approach and rationale]

### Alternative Approaches Considered
1. **[Approach 1]**: [Why not chosen]
2. **[Approach 2]**: [Why not chosen]

### Key Design Decisions
1. [Decision 1]: [Rationale]
2. [Decision 2]: [Rationale]

## Implementation Steps

### Phase 1: Preparation
- [ ] [Task 1]
- [ ] [Task 2]

### Phase 2: Core Implementation
- [ ] [Task 1] - [File/component affected]
- [ ] [Task 2] - [File/component affected]
- [ ] [Task 3] - [File/component affected]

### Phase 3: Testing
- [ ] Write unit tests for [component]
- [ ] Write integration tests for [feature]
- [ ] Update existing tests if needed
- [ ] Verify test coverage (target: 80%+)

### Phase 4: Verification
- [ ] Run `uv run pytest -m unit`
- [ ] Run `uv run pytest -m integration`
- [ ] Check diagnostics (no errors)
- [ ] Run linter (ruff)
- [ ] Manual testing of edge cases

### Phase 5: Documentation
- [ ] Update code docstrings
- [ ] Update relevant documentation files (if any)
- [ ] Add inline comments only where absolutely necessary

## Files to Modify/Create

### Modify
- `path/to/file1.py`: [Description of changes]
- `path/to/file2.py`: [Description of changes]

### Create (if necessary)
- `path/to/newfile.py`: [Purpose and reason for new file]

### Tests
- `tests/test_feature.py`: [New or modified tests]

## Risk Mitigation

### Potential Risks
1. **[Risk 1]**: [Mitigation strategy]
2. **[Risk 2]**: [Mitigation strategy]

### Edge Cases to Handle
- [Edge case 1]: [How to handle]
- [Edge case 2]: [How to handle]

## Testing Strategy

### Unit Tests
- [Test scenario 1]
- [Test scenario 2]

### Integration Tests
- [Test scenario 1]
- [Test scenario 2]

### Manual Testing Checklist
- [ ] [Test case 1]
- [ ] [Test case 2]

## Success Criteria
- [ ] All tests passing (unit + integration)
- [ ] No diagnostic errors
- [ ] Code follows project style guidelines
- [ ] Test coverage ≥ 80%
- [ ] Edge cases handled
- [ ] Documentation updated

## Open Questions
[Any uncertainties or areas needing clarification before implementation]

## Notes for Implementation
[Additional context, gotchas, or reminders for the implementation phase]
```

### 6. Save the Plan

**File Naming Convention**: `{feature-name-kebab-case}_{YYYY-MM-DD}.md`

Examples:
- `add-user-authentication_2025-10-28.md`
- `fix-database-connection-bug_2025-10-28.md`
- `improve-api-performance_2025-10-28.md`

Save to: `/workspaces/claude-code-pro/docs/plan/{filename}`

### 7. Present Plan to User

After saving the plan:
1. Show the file path where the plan was saved
2. Provide a concise summary (3-5 bullet points)
3. Highlight any critical risks or open questions
4. Ask for user approval to proceed with implementation
5. Mention that Sonnet will handle implementation after approval

## Decision Matrix: /plan vs Agent-OS

### Use `/plan` for:
- ✅ Small to medium features (1-3 files)
- ✅ Bug fixes (even if touching multiple files)
- ✅ Performance improvements
- ✅ Refactoring existing code
- ✅ Adding tests
- ✅ Documentation improvements

### Use Agent-OS for:
- ❌ Large features (4+ files)
- ❌ Architecture changes
- ❌ API modifications affecting multiple services
- ❌ Database schema changes
- ❌ Multi-step refactoring across modules
- ❌ New major components or services

## Key Principles

- **First Principles Thinking**: Break down to fundamental truths
- **Systems Thinking**: Consider interconnections and feedback loops
- **Evidence-Based**: Use codebase analysis, not assumptions
- **Risk-Aware**: Identify and mitigate potential issues
- **Test-Driven**: Plan testing strategy upfront
- **Pragmatic**: Balance perfection with practicality

## Output Expectations

The plan should be:
- **Comprehensive**: Cover all aspects of implementation
- **Actionable**: Clear steps that can be executed
- **Risk-Aware**: Identify potential issues and mitigations
- **Evidence-Based**: Grounded in actual codebase analysis
- **Test-Focused**: Include clear testing strategy
- **Concise**: Detailed but not verbose

## After Planning

Once the plan is saved and approved:
1. Switch to Sonnet for implementation (faster, cost-effective)
2. Follow the plan step-by-step
3. Use TodoWrite to track progress
4. Run tests after each significant change
5. Update the plan if requirements change during implementation

---

**Remember**: This is a planning tool for smaller changes. For complex features requiring comprehensive specification, use Agent-OS spec-driven development instead.

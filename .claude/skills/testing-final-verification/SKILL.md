---
name: Testing Final Verification
description: Enforce evidence-based completion verification by requiring fresh execution of verification commands and confirmation of output before making any success claims, ensuring work is genuinely complete rather than assumed complete. Use this skill when about to claim that work is complete, finished, or done, when about to state that tests are passing or a test suite succeeds, when preparing to commit changes to version control, when about to create pull requests or merge requests, when claiming that a bug has been fixed or resolved, when stating that build processes succeed or compile without errors, when reporting that linting, formatting, or code quality checks pass, when delegating work to agents and receiving success reports that need independent verification, when moving from one task to the next in a multi-step implementation, when about to use words like "should work", "probably works", "seems to", "looks correct", or other qualifying language that implies uncertainty, when feeling satisfied with work and ready to mark tasks complete, when expressing confidence without having run verification ("I'm confident this works"), when trusting partial verification as proof of complete success, when tired or under pressure and wanting to finish quickly, during code reviews when verifying that claimed changes actually work, when implementing regression tests and need to verify they fail before the fix (red-green cycle), or before any communication that implies success, completion, or correctness of implemented functionality.
---

# Verification Before Completion

## When to use this skill

- When about to claim work is complete, done, finished, or ready for review
- When preparing to use any variation of success language ("tests pass", "build succeeds", "linter is clean", "bug is fixed")
- Before committing changes with git commit or staging files with git add
- Before creating pull requests, merge requests, or pushing to remote repositories
- When about to mark a task or todo item as completed in task tracking systems
- When moving from one implementation step to the next in a multi-step feature
- When delegating work to agents, automation, or team members and verifying their reported success
- Before using uncertain language like "should work", "probably passes", "seems correct", "looks good"
- When feeling satisfied or confident about work without having just run verification commands
- When about to express positive sentiment about work state ("Great!", "Perfect!", "Done!", "All set!")
- Before reporting to stakeholders, managers, or team members that something is working
- When implementing Test-Driven Development and verifying the red-green cycle (test fails, then passes)
- When trusting linter success as proof that builds will succeed (they're different checks)
- When relying on agent success reports without independently checking the actual changes
- When tired, under time pressure, or eager to finish and move on
- Before any statement that implies correctness, completion, or successful implementation

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

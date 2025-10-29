---
name: Testing Test Writing
description: Write focused tests for core user flows and critical paths with clear test names, behavior-focused assertions, mocked external dependencies, and fast execution, deferring edge case testing until explicitly required. Use this skill when creating or modifying test files, writing unit tests, integration tests, or test cases for any feature. Apply when writing test files (test/, __tests__/, spec/, .test.js, .spec.ts, test_*.py), implementing tests for core user workflows, testing critical business logic, mocking external dependencies (databases, APIs, file systems), writing descriptive test names, creating fast-running unit tests, or adding tests at logical completion points of feature development. Use for any task involving test creation, test coverage, test strategy, or test-driven development.
---

# Testing Test Writing

## When to use this skill

- When creating or modifying test files (test/, __tests__/, *.test.js, *.spec.ts, test_*.py)
- When writing unit tests for core business logic and critical user workflows
- When implementing integration tests at logical feature completion points
- When writing test names that clearly describe what is being tested and expected outcome
- When mocking external dependencies like databases, APIs, or file systems to isolate units
- When focusing tests on behavior (what the code does) rather than implementation details
- When ensuring unit tests execute quickly (milliseconds) for frequent developer runs
- When testing core user flows and primary workflows (deferring edge cases unless critical)
- When writing minimal tests during feature development, focusing on main functionality
- When avoiding excessive testing of non-critical utilities or secondary workflows
- When deciding test coverage strategy for new features or refactoring

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle testing test writing.

## Instructions

- **Write Minimal Tests During Development**: Do NOT write tests for every change or intermediate step. Focus on completing the feature implementation first, then add strategic tests only at logical completion points
- **Test Only Core User Flows**: Write tests exclusively for critical paths and primary user workflows. Skip writing tests for non-critical utilities and secondary workflows until if/when you're instructed to do so.
- **Defer Edge Case Testing**: Do NOT test edge cases, error states, or validation logic unless they are business-critical. These can be addressed in dedicated testing phases, not during feature development.
- **Test Behavior, Not Implementation**: Focus tests on what the code does, not how it does it, to reduce brittleness
- **Clear Test Names**: Use descriptive names that explain what's being tested and the expected outcome
- **Mock External Dependencies**: Isolate units by mocking databases, APIs, file systems, and other external services
- **Fast Execution**: Keep unit tests fast (milliseconds) so developers run them frequently during development

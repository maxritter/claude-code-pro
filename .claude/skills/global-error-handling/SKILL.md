---
name: Global Error Handling
description: Implement robust error handling with user-friendly messages, specific exception types, fail-fast validation, centralized error handling, graceful degradation, retry strategies, and proper resource cleanup. Use this skill when implementing error handling logic, try-catch blocks, exception handling, error boundaries, validation checks, API error responses, or resource cleanup. Apply when writing error handling in API controllers, service layers, frontend error boundaries, input validation, external service calls with retry logic, error logging, user-facing error messages, finally blocks for resource cleanup, or when establishing centralized error handling patterns at application boundaries. Use for any task involving exception handling, error recovery, graceful failure, or user error communication.
---

# Global Error Handling

## When to use this skill

- When implementing error handling in API controllers, service layers, or application boundaries
- When writing try-catch blocks or exception handling in any language
- When validating input and checking preconditions to fail fast with clear errors
- When providing user-friendly error messages that avoid exposing technical details
- When using specific exception types rather than generic errors for targeted handling
- When establishing centralized error handling patterns at API or controller layers
- When implementing graceful degradation when non-critical services fail
- When adding retry strategies with exponential backoff for external service calls
- When ensuring resource cleanup with finally blocks or equivalent mechanisms
- When creating error boundaries in React or similar frontend frameworks
- When logging errors for debugging while showing safe messages to users

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle global error handling.

## Instructions

- **User-Friendly Messages**: Provide clear, actionable error messages to users without exposing technical details or security information
- **Fail Fast and Explicitly**: Validate input and check preconditions early; fail with clear error messages rather than allowing invalid state
- **Specific Exception Types**: Use specific exception/error types rather than generic ones to enable targeted handling
- **Centralized Error Handling**: Handle errors at appropriate boundaries (controllers, API layers) rather than scattering try-catch blocks everywhere
- **Graceful Degradation**: Design systems to degrade gracefully when non-critical services fail rather than breaking entirely
- **Retry Strategies**: Implement exponential backoff for transient failures in external service calls
- **Clean Up Resources**: Always clean up resources (file handles, connections) in finally blocks or equivalent mechanisms

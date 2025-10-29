---
name: Global Validation
description: Implement comprehensive validation with server-side enforcement, client-side UX feedback, early failure, specific error messages, allowlists over blocklists, type checking, input sanitization, and consistent validation across all entry points. Use this skill when implementing validation logic in forms, API endpoints, data models, user inputs, or any data processing. Apply when validating form inputs, API request parameters, database model fields, implementing client-side validation for user experience, enforcing server-side validation for security, sanitizing user input to prevent injection attacks, checking data types and formats, validating business rules, or providing field-specific error messages. Use for any task involving input validation, data integrity checks, security validation, or user input processing.
---

# Global Validation

## When to use this skill

- When implementing server-side validation in API endpoints, controllers, or service layers
- When adding client-side validation to forms for immediate user feedback
- When validating user input at any entry point (web forms, API calls, background jobs)
- When defining validation rules on database models or schema definitions
- When implementing fail-fast validation to reject invalid data early in processing
- When providing specific, field-level error messages to help users correct their input
- When using allowlists to define what is valid rather than blocklists for what isn't
- When checking data types, formats, ranges, and required fields systematically
- When sanitizing user input to prevent SQL injection, XSS, or command injection
- When validating business rules like sufficient balance, valid dates, or authorization
- When ensuring validation is applied consistently across all application entry points

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle global validation.

## Instructions

- **Validate on Server Side**: Always validate on the server; never trust client-side validation alone for security or data integrity
- **Client-Side for UX**: Use client-side validation to provide immediate user feedback, but duplicate checks server-side
- **Fail Early**: Validate input as early as possible and reject invalid data before processing
- **Specific Error Messages**: Provide clear, field-specific error messages that help users correct their input
- **Allowlists Over Blocklists**: When possible, define what is allowed rather than trying to block everything that's not
- **Type and Format Validation**: Check data types, formats, ranges, and required fields systematically
- **Sanitize Input**: Sanitize user input to prevent injection attacks (SQL, XSS, command injection)
- **Business Rule Validation**: Validate business rules (e.g., sufficient balance, valid dates) at the appropriate application layer
- **Consistent Validation**: Apply validation consistently across all entry points (web forms, API endpoints, background jobs)

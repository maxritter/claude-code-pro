---
name: Backend API
description: Design and implement RESTful API endpoints following REST principles with proper HTTP methods, status codes, and resource-based URLs. Use this skill when creating or modifying API endpoints, route handlers, controllers, or API configuration files. Apply when working on REST API design, endpoint implementations, API versioning, request/response handling, HTTP method routing (GET, POST, PUT, PATCH, DELETE), query parameter filtering, API rate limiting, or any file that defines API routes such as routes.py, api.js, controllers/, endpoints/, or API documentation files.
---

# Backend API

## When to use this skill

- When creating or modifying API endpoint files (routes.py, api.js, controllers/, endpoints/, etc.)
- When implementing REST API route handlers and controllers
- When designing resource-based URL structures and HTTP method routing
- When working with API versioning strategies in URL paths or headers
- When implementing query parameters for filtering, sorting, pagination, or search
- When configuring HTTP status codes for API responses
- When setting up rate limiting headers or API middleware
- When writing API documentation or OpenAPI/Swagger specifications
- When refactoring existing API endpoints for consistency or REST compliance

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle backend API.

## Instructions

- **RESTful Design**: Follow REST principles with clear resource-based URLs and appropriate HTTP methods (GET, POST, PUT, PATCH, DELETE)
- **Consistent Naming**: Use consistent, lowercase, hyphenated or underscored naming conventions for endpoints across the API
- **Versioning**: Implement API versioning strategy (URL path or headers) to manage breaking changes without disrupting existing clients
- **Plural Nouns**: Use plural nouns for resource endpoints (e.g., `/users`, `/products`) for consistency
- **Nested Resources**: Limit nesting depth to 2-3 levels maximum to keep URLs readable and maintainable
- **Query Parameters**: Use query parameters for filtering, sorting, pagination, and search rather than creating separate endpoints
- **HTTP Status Codes**: Return appropriate, consistent HTTP status codes that accurately reflect the response (200, 201, 400, 404, 500, etc.)
- **Rate Limiting Headers**: Include rate limit information in response headers to help clients manage their usage

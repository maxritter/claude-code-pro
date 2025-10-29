---
name: Backend Queries
description: Write secure, optimized database queries using parameterized queries, eager loading to prevent N+1 problems, and strategic indexing for performance. Use this skill when writing SQL queries, ORM queries, database interactions, or optimizing data fetching logic. Apply when working with query files, repository patterns, data access layers, SQL statements, ORM methods (ActiveRecord, Sequelize, Prisma queries), JOIN operations, WHERE clauses, preventing SQL injection, implementing eager loading or includes, adding query timeouts, wrapping operations in transactions, or caching expensive queries. Use for any task involving database reads, writes, complex queries, query optimization, or data fetching performance.
---

# Backend Queries

## When to use this skill

- When writing SQL queries or ORM query methods in any backend file
- When implementing repository patterns or data access layers
- When optimizing queries to prevent N+1 query problems using eager loading or joins
- When selecting specific columns instead of using SELECT * for performance
- When adding indexes to columns used in WHERE, JOIN, or ORDER BY clauses
- When implementing parameterized queries to prevent SQL injection vulnerabilities
- When wrapping related database operations in transactions for data consistency
- When setting query timeouts to prevent runaway queries
- When caching results of complex or frequently-executed queries
- When refactoring slow queries or investigating query performance issues

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle backend queries.

## Instructions

- **Prevent SQL Injection**: Always use parameterized queries or ORM methods; never interpolate user input into SQL strings
- **Avoid N+1 Queries**: Use eager loading or joins to fetch related data in a single query instead of multiple queries
- **Select Only Needed Data**: Request only the columns you need rather than using SELECT * for better performance
- **Index Strategic Columns**: Index columns used in WHERE, JOIN, and ORDER BY clauses for query optimization
- **Use Transactions for Related Changes**: Wrap related database operations in transactions to maintain data consistency
- **Set Query Timeouts**: Implement timeouts to prevent runaway queries from impacting system performance
- **Cache Expensive Queries**: Cache results of complex or frequently-run queries when appropriate

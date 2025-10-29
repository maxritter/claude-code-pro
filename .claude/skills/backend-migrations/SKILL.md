---
name: Backend Migrations
description: Create and manage database migrations with reversible changes, proper naming conventions, and zero-downtime deployment strategies. Use this skill when creating database migration files, modifying schema, adding or removing tables/columns, managing indexes, or handling data migrations. Apply when working with migration files (e.g., db/migrate/, migrations/, alembic/, sequelize migrations), schema changes, database versioning, rollback implementations, or when you need to ensure backwards compatibility during deployments. Use for any task involving database structure changes, index creation, constraint modifications, or data transformation scripts.
---

# Backend Migrations

## When to use this skill

- When creating new database migration files (db/migrate/, migrations/, alembic/, etc.)
- When modifying database schema such as adding, removing, or altering tables and columns
- When implementing rollback/down methods for reversible migrations
- When creating indexes on database tables, especially large tables requiring concurrent indexing
- When writing data migrations to transform or populate data
- When planning zero-downtime deployments that require backwards-compatible schema changes
- When establishing naming conventions for migration files
- When separating schema changes from data migrations
- When reviewing or modifying existing migrations for safety and clarity

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle backend migrations.

## Instructions

- **Reversible Migrations**: Always implement rollback/down methods to enable safe migration reversals
- **Small, Focused Changes**: Keep each migration focused on a single logical change for clarity and easier troubleshooting
- **Zero-Downtime Deployments**: Consider deployment order and backwards compatibility for high-availability systems
- **Separate Schema and Data**: Keep schema changes separate from data migrations for better rollback safety
- **Index Management**: Create indexes on large tables carefully, using concurrent options when available to avoid locks
- **Naming Conventions**: Use clear, descriptive names that indicate what the migration does
- **Version Control**: Always commit migrations to version control and never modify existing migrations after deployment

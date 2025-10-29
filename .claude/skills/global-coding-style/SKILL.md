---
name: Global Coding Style
description: Write clean, consistent code following naming conventions, automated formatting, DRY principles, small focused functions, and meaningful variable names across all languages and files. Use this skill when writing or modifying any code file in any language or framework. Apply when naming variables, functions, classes, or files, when refactoring code to remove duplication, when breaking down large functions into smaller focused ones, when cleaning up dead code or unused imports, when ensuring consistent indentation and formatting, when choosing descriptive names over abbreviations, or when following the project's linting and formatting rules (ESLint, Prettier, RuboCop, Black, etc.). Use for any task involving code organization, readability, maintainability, or style consistency across the codebase.
---

# Global Coding Style

## When to use this skill

- When writing or modifying any code file in any language (JavaScript, Python, Ruby, Java, etc.)
- When naming variables, functions, classes, or files to ensure descriptive, meaningful names
- When refactoring code to follow DRY principle and eliminate duplication
- When breaking down large functions into smaller, focused, single-purpose functions
- When removing dead code, commented-out blocks, or unused imports
- When ensuring consistent indentation and formatting with project style guides
- When configuring or running automated formatters (Prettier, ESLint, Black, RuboCop)
- When reviewing code for naming convention consistency across the codebase
- When avoiding abbreviations or single-letter variables outside narrow contexts
- When deciding whether backward compatibility logic is needed for changes
- When organizing code structure for better readability and testability

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle global coding style.

## Instructions

- **Consistent Naming Conventions**: Establish and follow naming conventions for variables, functions, classes, and files across the codebase
- **Automated Formatting**: Maintain consistent code style (indenting, line breaks, etc.)
- **Meaningful Names**: Choose descriptive names that reveal intent; avoid abbreviations and single-letter variables except in narrow contexts
- **Small, Focused Functions**: Keep functions small and focused on a single task for better readability and testability
- **Consistent Indentation**: Use consistent indentation (spaces or tabs) and configure your editor/linter to enforce it
- **Remove Dead Code**: Delete unused code, commented-out blocks, and imports rather than leaving them as clutter
- **Backward compatability only when required:** Unless specifically instructed otherwise, assume you do not need to write additional code logic to handle backward compatability.
- **DRY Principle**: Avoid duplication by extracting common logic into reusable functions or modules

---
name: Frontend Components
description: Design reusable, composable UI components following single responsibility principle with clear interfaces, encapsulation, and minimal props. Use this skill when creating or modifying frontend components in any framework (React, Vue, Svelte, web components) or component files. Apply when working with .jsx, .tsx, .vue, .svelte files in component directories (components/, src/components/, ui/, lib/), defining component props and interfaces, implementing component composition patterns, managing component-level state, creating reusable UI elements (buttons, forms, cards, modals), documenting component APIs, or refactoring components for better reusability and maintainability.
---

# Frontend Components

## When to use this skill

- When creating new component files (.jsx, .tsx, .vue, .svelte, etc.)
- When modifying existing components in component directories (components/, ui/, lib/)
- When defining component props, interfaces, or prop types
- When implementing component composition to build complex UIs from simpler components
- When managing component-level state and deciding when to lift state up
- When creating reusable UI elements like buttons, forms, cards, modals, or layouts
- When documenting component APIs, props, and usage examples
- When refactoring monolithic components into smaller, focused components
- When designing component interfaces for team adoption
- When implementing encapsulation to keep internal component details private

This Skill provides Claude Code with specific guidance on how to adhere to coding standards as they relate to how it should handle frontend components.

## Instructions

- **Single Responsibility**: Each component should have one clear purpose and do it well
- **Reusability**: Design components to be reused across different contexts with configurable props
- **Composability**: Build complex UIs by combining smaller, simpler components rather than monolithic structures
- **Clear Interface**: Define explicit, well-documented props with sensible defaults for ease of use
- **Encapsulation**: Keep internal implementation details private and expose only necessary APIs
- **Consistent Naming**: Use clear, descriptive names that indicate the component's purpose and follow team conventions
- **State Management**: Keep state as local as possible; lift it up only when needed by multiple components
- **Minimal Props**: Keep the number of props manageable; if a component needs many props, consider composition or splitting it
- **Documentation**: Document component usage, props, and provide examples for easier adoption by team members

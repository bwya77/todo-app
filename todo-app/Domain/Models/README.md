# Domain Models

This directory contains the domain models for the application. These are the core business objects that represent the actual data and business logic of the application, decoupled from the CoreData implementation.

## Model Naming Conventions

All model files should follow the naming convention:
- Domain models: `[Name].swift`
- Value objects: `[Name]Value.swift`
- Enums: `[Name]Type.swift`

## Implementation Notes

Domain models should be implemented as structures that are separate from the CoreData entities. They should be immutable when possible, and contain no UI logic or persistence concerns.

## Current Models

- `ViewType.swift`: Enum representing the different view types in the application.

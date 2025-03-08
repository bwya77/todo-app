# Repositories

This directory will contain the repository interfaces for the application. Repositories are responsible for data access and persistence operations.

## Repository Naming Conventions

All repository files should follow the naming convention:
- Repository interfaces: `[Name]Repository.swift`
- Repository implementations: `[Name]RepositoryImpl.swift`

## Implementation Notes

Repositories should be protocol-based, allowing for different implementations (CoreData, REST API, etc.). They should work with domain models, not CoreData entities directly.

## Planned Repositories

- `TaskRepository`: Interface for task data operations
- `ProjectRepository`: Interface for project data operations
- `TagRepository`: Interface for tag data operations

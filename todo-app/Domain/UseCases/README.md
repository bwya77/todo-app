# Use Cases

This directory will contain the use case interfaces and implementations for the application. Use cases represent specific actions or operations that the application can perform.

## Use Case Naming Conventions

All use case files should follow the naming convention:
- Use case interfaces: `[Action][Subject]UseCase.swift` (e.g. CreateTaskUseCase)
- Use case implementations: `[Action][Subject]UseCaseImpl.swift`

## Implementation Notes

Use cases should be protocol-based for better testability. They should encapsulate a single responsibility or action, and delegate to services and repositories as needed.

## Planned Use Cases

- `CreateTaskUseCase`: Use case for creating a new task
- `UpdateTaskUseCase`: Use case for updating an existing task
- `DeleteTaskUseCase`: Use case for deleting a task
- `GetTasksUseCase`: Use case for retrieving tasks based on filters

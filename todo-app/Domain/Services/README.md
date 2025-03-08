# Services

This directory will contain the service interfaces and implementations for the application. Services provide business logic that may span multiple repositories or external integrations.

## Service Naming Conventions

All service files should follow the naming convention:
- Service interfaces: `[Name]Service.swift`
- Service implementations: `[Name]ServiceImpl.swift`

## Implementation Notes

Services should be protocol-based for better testability. They should orchestrate operations between repositories and other services, applying business logic.

## Planned Services

- `TaskService`: Business logic for task management
- `CalendarService`: Business logic for calendar-related operations
- `NotificationService`: Business logic for notifications and reminders

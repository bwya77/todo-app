# Persistence

This directory contains the persistence-related code for the application. It includes the persistence controller and related utilities.

## Naming Conventions

Files should be named according to their responsibility:
- `PersistenceController.swift`: Main controller for CoreData operations
- Custom extensions or helpers: `[Type]+[Functionality].swift`

## Implementation Notes

- The persistence layer should be abstracted behind repository interfaces.
- Domain models should be mapped to/from CoreData entities.
- Error handling should be robust and consistent.
- Batch operations should be used where appropriate for performance.

## Current Files

- `PersistenceController.swift`: Main controller for CoreData stack initialization and management

## Planned Improvements

- Add value transformers for proper color serialization
- Implement batch operations for better performance
- Add proper error handling and validation
- Add persistent history tracking for potential sync features

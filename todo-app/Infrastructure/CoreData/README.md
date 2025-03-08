# CoreData

This directory contains the CoreData model and related extensions for the application.

## Naming Conventions

- CoreData model: `todo_app.xcdatamodeld`
- Extensions: `[EntityName]+Extensions.swift`

## Implementation Notes

- CoreData entities should have appropriate validation and default values.
- Relationships should have proper delete rules.
- Optionality should be set appropriately for attributes.
- Extensions should provide convenience methods for entity creation and management.

## Current Files

- `todo_app.xcdatamodeld`: Main CoreData model for the application

## Planned Improvements

- Add dedicated extensions for each entity type
- Implement validation and constraints
- Add convenience methods for entity creation and querying
- Implement proper error handling
- Add value transformers for complex data types

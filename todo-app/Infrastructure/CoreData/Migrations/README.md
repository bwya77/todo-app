# Core Data Migration - Adding Task Reordering

## Overview

This directory contains migration plans for Core Data model changes. The current migration adds support for task reordering via drag and drop by adding a `displayOrder` attribute to the `Item` entity.

## Migration Process

### 1. Schema Change

The migration adds a new attribute:

- `displayOrder` (Int32): Represents the position of a task in a list.

### 2. Data Migration

The `AddDisplayOrderMigrationPolicy` class handles migrating existing tasks:

- Each task is assigned a display order based on its creation date
- This preserves the chronological ordering of existing tasks
- We convert the creation date to a timestamp (seconds since reference date)

### 3. Usage of Display Order

After migration, tasks can be reordered by:

- Dragging and dropping in the UI
- The new order is preserved by updating the `displayOrder` attribute

## Implementation Notes

- The migration is lightweight and non-destructive
- Existing tasks maintain their relative ordering
- New tasks are assigned an incrementing display order value

## Testing

Before deploying, test the migration by:

1. Creating a test database with the old schema
2. Running the migration
3. Verifying task ordering is preserved
4. Testing drag and drop reordering functionality

## Reversibility

This migration is reversible - if the `displayOrder` attribute is removed, tasks would fall back to the default sort order (typically by due date and priority).

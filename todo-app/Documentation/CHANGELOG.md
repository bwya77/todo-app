# Changelog

## [Unreleased] - 2025-03-13

### Added
- NSFetchedResultsController implementation for improved list management
- Batch fetching support for calendar views with optimized performance
- New dedicated fetch request factories for all common query patterns
- Enhanced ViewModels leveraging CoreData optimizations
- New `EnhancedTaskListView` that uses NSFetchedResultsController
- Specialized `CalendarTaskViewModel` for optimized calendar operations
- Comprehensive documentation of fetch request improvements

### Changed
- Updated `TaskFetchRequestFactory` with additional optimization methods
- Enhanced fetch requests with relationship prefetching
- Improved task grouping with section support
- Optimized memory usage for large task lists

### Fixed
- Memory inefficiencies when displaying large task lists
- Performance issues when scrolling through calendar views
- Inconsistent fetch request patterns across the application

## [1.0.0] - 2025-03-04

### Added
- Initial release of the todo-app
- Basic task management functionality
- Project organization support
- Date-based task views
- Simple list-based UI

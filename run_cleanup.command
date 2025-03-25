#!/bin/bash

cd "$(dirname "$0")"

# Delete unused files that might cause conflicts
echo "Cleaning up unused files..."

# Remove unused AppEnvironment.swift (we don't need it anymore with our simplified approach)
if [ -f "./todo-app/Presentation/Utilities/AppEnvironment.swift" ]; then
  rm "./todo-app/Presentation/Utilities/AppEnvironment.swift"
  echo "Removed AppEnvironment.swift"
fi

# Remove other potentially conflicting files
if [ -f "./todo-app/Presentation/Utilities/SidebarHoverState.swift" ]; then
  rm "./todo-app/Presentation/Utilities/SidebarHoverState.swift"
  echo "Removed SidebarHoverState.swift"
fi

if [ -f "./todo-app/Presentation/Components/Common/SidebarHoverEnvironment.swift" ]; then
  rm "./todo-app/Presentation/Components/Common/SidebarHoverEnvironment.swift"
  echo "Removed SidebarHoverEnvironment.swift"
fi

if [ -f "./todo-app/Presentation/Utilities/SidebarViewExtensions.swift" ]; then
  rm "./todo-app/Presentation/Utilities/SidebarViewExtensions.swift"
  echo "Removed SidebarViewExtensions.swift"
fi

echo "Cleanup complete!"

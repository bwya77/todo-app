#!/bin/bash

# Delete unused files that might cause conflicts
echo "Cleaning up unused files..."

# Remove unused AppEnvironment.swift (we don't need it anymore with our simplified approach)
if [ -f "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/AppEnvironment.swift" ]; then
  rm "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/AppEnvironment.swift"
  echo "Removed AppEnvironment.swift"
fi

# Remove other potentially conflicting files
if [ -f "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/SidebarHoverState.swift" ]; then
  rm "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/SidebarHoverState.swift"
  echo "Removed SidebarHoverState.swift"
fi

if [ -f "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Components/Common/SidebarHoverEnvironment.swift" ]; then
  rm "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Components/Common/SidebarHoverEnvironment.swift"
  echo "Removed SidebarHoverEnvironment.swift"
fi

if [ -f "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/SidebarViewExtensions.swift" ]; then
  rm "/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Utilities/SidebarViewExtensions.swift"
  echo "Removed SidebarViewExtensions.swift"
fi

echo "Cleanup complete!"

#!/bin/bash

# Ensure all .sh files are executable
find ./scripts -type f -name "*.sh" -exec chmod +x {} \;

echo "Executable permissions added to:"
find ./scripts -type f -name "*.sh" | sed 's/^/  ➤ /'
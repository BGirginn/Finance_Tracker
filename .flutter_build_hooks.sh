#!/bin/bash

# Flutter build hooks - automatically called by Flutter before builds
# This ensures all prerequisites are met

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run pre-build script if it exists
if [ -f "$SCRIPT_DIR/scripts/pre_build.sh" ]; then
    bash "$SCRIPT_DIR/scripts/pre_build.sh"
fi

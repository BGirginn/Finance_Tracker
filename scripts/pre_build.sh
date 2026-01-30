#!/bin/bash

# Pre-build script - runs before any build
# This ensures database code and dependencies are ready

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "🔧 Running pre-build checks..."

# 1. Generate database code if needed
if [ ! -f "lib/core/database/database.g.dart" ] || \
   [ "lib/core/database/database.dart" -nt "lib/core/database/database.g.dart" ]; then
    echo "🗄️  Generating database code..."
    flutter pub run build_runner build --delete-conflicting-outputs || true
fi

# 2. Check iOS pods (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]] && [ -d "ios" ]; then
    if [ ! -d "ios/Pods" ] || [ "ios/Podfile" -nt "ios/Pods" ]; then
        echo "🍎 Installing CocoaPods dependencies..."
        cd ios
        if command -v pod &> /dev/null; then
            pod install --repo-update || pod install || true
        else
            echo "⚠️  CocoaPods not found. Run: sudo gem install cocoapods"
        fi
        cd ..
    fi
fi

# 3. Generate Android icons if missing (only if flutter_launcher_icons is configured)
if [ -d "android" ] && grep -q "flutter_launcher_icons" pubspec.yaml 2>/dev/null; then
    if [ ! -f "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" ]; then
        echo "📱 Generating Android icons..."
        "$SCRIPT_DIR/generate_icons.sh" || true
    fi
fi

echo "✅ Pre-build checks complete"

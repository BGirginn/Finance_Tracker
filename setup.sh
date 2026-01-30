#!/bin/bash

# Finance App Setup Script
# This script prepares the project for building in both Android Studio and Xcode

echo "🚀 Setting up Finance App..."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Get Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Generate database code
echo "🗄️  Generating database code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Generate Android icons if flutter_launcher_icons is configured
if grep -q "flutter_launcher_icons" pubspec.yaml 2>/dev/null; then
    echo "📱 Generating Android launcher icons..."
    if flutter pub run flutter_launcher_icons:main 2>/dev/null; then
        echo "✅ Android icons generated"
    else
        # Fallback: run icon generation script
        if [ -f "scripts/generate_icons.sh" ]; then
            bash scripts/generate_icons.sh
        fi
    fi
fi

# Setup Android
echo "🤖 Setting up Android..."
if [ -d "android" ]; then
    cd android
    
    # Create local.properties if it doesn't exist
    if [ ! -f "local.properties" ]; then
        echo "📝 Creating local.properties..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            SDK_PATH="$HOME/Library/Android/sdk"
        else
            # Linux
            SDK_PATH="$HOME/Android/Sdk"
        fi
        
        if [ -d "$SDK_PATH" ]; then
            echo "sdk.dir=$SDK_PATH" > local.properties
            echo "✅ Created local.properties with SDK path: $SDK_PATH"
        else
            echo "⚠️  Android SDK not found at $SDK_PATH"
            echo "   Please create android/local.properties manually with:"
            echo "   sdk.dir=/path/to/your/android/sdk"
        fi
    fi
    
    cd ..
fi

# Setup iOS
echo "🍎 Setting up iOS..."
if [ -d "ios" ]; then
    cd ios
    
    # Check CocoaPods
    if ! command -v pod &> /dev/null; then
        echo "⚠️  CocoaPods is not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo gem install cocoapods
        else
            echo "❌ CocoaPods installation requires macOS"
        fi
    fi
    
    if command -v pod &> /dev/null; then
        echo "📦 Installing CocoaPods dependencies..."
        pod install --repo-update || pod install
        
        if [ $? -eq 0 ]; then
            echo "✅ CocoaPods dependencies installed"
        else
            echo "⚠️  CocoaPods installation had issues. You may need to run 'pod install' manually."
        fi
    else
        echo "⚠️  CocoaPods not found. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v gem &> /dev/null; then
                sudo gem install cocoapods
                echo "📦 Installing CocoaPods dependencies..."
                pod install --repo-update || pod install
            fi
        fi
    fi
    
    cd ..
fi

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Make scripts executable
if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "✅ Automatic features enabled:"
echo "   - Database code will auto-generate before builds"
echo "   - Android icons are generated automatically"
echo "   - iOS pods will auto-install before builds"
echo ""
echo "📝 Manual step required:"
echo "   - iOS: Signing must be configured in Xcode (Signing & Capabilities → Team)"
echo ""
echo "📱 To build for Android:"
echo "   - Open android/ folder in Android Studio"
echo "   - Or run: flutter build apk"
echo ""
echo "🍎 To build for iOS:"
echo "   - Open ios/Runner.xcworkspace in Xcode"
echo "   - Configure signing in Signing & Capabilities"
echo "   - Or run: flutter build ios"
echo ""
echo "▶️  To run the app:"
echo "   flutter run"
echo ""
echo "📚 For detailed instructions, see:"
echo "   - QUICK_START.md"
echo "   - BUILD_INSTRUCTIONS.md"

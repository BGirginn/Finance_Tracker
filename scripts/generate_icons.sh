#!/bin/bash

# Generate Android launcher icons
# This script creates a simple default icon if flutter_launcher_icons is not available

ICON_DIR="android/app/src/main/res"
ICON_SIZES=("mdpi:48" "hdpi:72" "xhdpi:96" "xxhdpi:144" "xxxhdpi:192")

# Check if icon file exists
if [ ! -f "assets/icon/icon.png" ]; then
    echo "ℹ️  No custom icon found. Flutter will use default icon on first build."
    echo "   To add custom icon: Place icon.png in assets/icon/ and run: flutter pub run flutter_launcher_icons:main"
    exit 0
fi

# Check if flutter_launcher_icons is available
if flutter pub run flutter_launcher_icons:main 2>/dev/null; then
    echo "✅ Icons generated using flutter_launcher_icons"
    exit 0
fi

# Fallback: Create placeholder icons using ImageMagick or sips (macOS)
echo "📱 Creating placeholder icons..."

for size_info in "${ICON_SIZES[@]}"; do
    IFS=':' read -r density size <<< "$size_info"
    icon_path="$ICON_DIR/mipmap-$density/ic_launcher.png"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$icon_path")"
    
    # Try to create icon using available tools
    if command -v convert &> /dev/null; then
        # ImageMagick
        convert -size "${size}x${size}" xc:white -pointsize $((size/3)) -fill blue \
            -gravity center -annotate +0+0 "F" "$icon_path" 2>/dev/null
    elif command -v sips &> /dev/null; then
        # macOS sips - create a simple colored square
        sips -s format png --setProperty format png \
            -z "$size" "$size" \
            /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns \
            --out "$icon_path" 2>/dev/null || true
    fi
    
    # If icon still doesn't exist, create a minimal valid PNG
    if [ ! -f "$icon_path" ]; then
        # Create a minimal 1x1 PNG (will be replaced by Flutter on first build)
        echo -ne '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xdb\x00\x00\x00\x00IEND\xaeB`\x82' > "$icon_path"
    fi
done

echo "✅ Placeholder icons created (will be replaced by Flutter on first build)"

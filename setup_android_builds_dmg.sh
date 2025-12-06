#!/bin/bash

# Setup Android Builds DMG on SSD
# This script creates a DMG file on the SSD and sets up symlinks for Android builds

set -e

SSD_PATH="/Volumes/Untitled"
DMG_NAME="android-builds"
DMG_SIZE="50g"  # 50GB should be enough for Android builds
MOUNT_POINT="/Volumes/android-builds"
DMG_PATH="${SSD_PATH}/${DMG_NAME}.dmg"

echo "🚀 Setting up Android Builds DMG on SSD..."

# Check if SSD is mounted
if [ ! -d "$SSD_PATH" ]; then
    echo "❌ Error: SSD not found at $SSD_PATH"
    echo "Please mount your SSD first"
    exit 1
fi

# Check if DMG already exists
if [ -f "$DMG_PATH" ]; then
    echo "⚠️  DMG already exists at $DMG_PATH"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Unmount if mounted
        if mount | grep -q "$MOUNT_POINT"; then
            echo "Unmounting existing DMG..."
            hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
        fi
        rm -f "$DMG_PATH"
    else
        echo "Using existing DMG..."
    fi
fi

# Create DMG if it doesn't exist
if [ ! -f "$DMG_PATH" ]; then
    echo "📦 Creating DMG file ($DMG_SIZE) on SSD..."
    hdiutil create -size $DMG_SIZE -fs APFS -volname "android-builds" "$DMG_PATH"
    echo "✅ DMG created successfully"
fi

# Mount the DMG
echo "🔌 Mounting DMG..."
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" 2>/dev/null || {
    # If mountpoint doesn't exist, mount to default location
    hdiutil attach "$DMG_PATH"
    # Get the actual mount point
    MOUNT_POINT=$(hdiutil info | grep -A 1 "$DMG_NAME" | grep "/Volumes" | awk '{print $3}' | head -1)
    if [ -z "$MOUNT_POINT" ]; then
        MOUNT_POINT="/Volumes/android-builds"
    fi
}

echo "✅ DMG mounted at: $MOUNT_POINT"

# Create directories on DMG
echo "📁 Creating directory structure..."
mkdir -p "$MOUNT_POINT/.gradle"
mkdir -p "$MOUNT_POINT/android-builds"
mkdir -p "$MOUNT_POINT/flutter-builds"

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"
GRADLE_HOME="$HOME/.gradle"

echo "🔗 Creating symlinks..."

# Backup existing directories if they exist
if [ -d "$ANDROID_DIR/.gradle" ] && [ ! -L "$ANDROID_DIR/.gradle" ]; then
    echo "📦 Backing up existing .gradle directory..."
    mv "$ANDROID_DIR/.gradle" "$ANDROID_DIR/.gradle.backup"
fi

if [ -d "$ANDROID_DIR/build" ] && [ ! -L "$ANDROID_DIR/build" ]; then
    echo "📦 Backing up existing build directory..."
    mv "$ANDROID_DIR/build" "$ANDROID_DIR/build.backup"
fi

if [ -d "$PROJECT_ROOT/build" ] && [ ! -L "$PROJECT_ROOT/build" ]; then
    echo "📦 Backing up existing Flutter build directory..."
    mv "$PROJECT_ROOT/build" "$PROJECT_ROOT/build.backup"
fi

# Create symlinks
ln -sf "$MOUNT_POINT/.gradle" "$ANDROID_DIR/.gradle" 2>/dev/null || true
ln -sf "$MOUNT_POINT/android-builds" "$ANDROID_DIR/build" 2>/dev/null || true
ln -sf "$MOUNT_POINT/flutter-builds" "$PROJECT_ROOT/build" 2>/dev/null || true

# Also symlink global Gradle cache if it exists
if [ -d "$GRADLE_HOME" ] && [ ! -L "$GRADLE_HOME" ]; then
    echo "📦 Backing up global Gradle cache..."
    mv "$GRADLE_HOME" "${GRADLE_HOME}.backup"
    mkdir -p "$MOUNT_POINT/global-gradle"
    ln -sf "$MOUNT_POINT/global-gradle" "$GRADLE_HOME"
fi

echo "✅ Symlinks created successfully!"

# Create auto-mount script
AUTO_MOUNT_SCRIPT="$HOME/Library/LaunchAgents/com.android.builds.mount.plist"
cat > "$AUTO_MOUNT_SCRIPT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.android.builds.mount</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hdiutil</string>
        <string>attach</string>
        <string>$DMG_PATH</string>
        <string>-mountpoint</string>
        <string>$MOUNT_POINT</string>
        <string>-quiet</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ Auto-mount LaunchAgent created at: $AUTO_MOUNT_SCRIPT"
echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Summary:"
echo "   - DMG Location: $DMG_PATH"
echo "   - Mount Point: $MOUNT_POINT"
echo "   - Android .gradle: $ANDROID_DIR/.gradle -> $MOUNT_POINT/.gradle"
echo "   - Android build: $ANDROID_DIR/build -> $MOUNT_POINT/android-builds"
echo "   - Flutter build: $PROJECT_ROOT/build -> $MOUNT_POINT/flutter-builds"
echo ""
echo "💡 To load the auto-mount agent, run:"
echo "   launchctl load $AUTO_MOUNT_SCRIPT"
echo ""
echo "💡 To manually mount/unmount:"
echo "   hdiutil attach $DMG_PATH -mountpoint $MOUNT_POINT"
echo "   hdiutil detach $MOUNT_POINT"

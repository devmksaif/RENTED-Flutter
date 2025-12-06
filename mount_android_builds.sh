#!/bin/bash

# Script to mount Android builds DMG and create symlinks
# Run this script to mount the DMG and set up symlinks

DMG_PATH="/Volumes/Untitled/android-builds.dmg.sparseimage"
MOUNT_POINT="/Volumes/android-builds"
PROJECT_ROOT="/Users/Apple/StudioProjects/RENTED"

# Mount the DMG
echo "🔌 Mounting Android builds DMG..."
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" 2>/dev/null || {
    echo "⚠️  DMG already mounted or mount failed"
    # Check if it's mounted at a different location
    MOUNT_POINT=$(hdiutil info | grep "android-builds" | grep "/Volumes" | awk '{print $3}' | head -1)
    if [ -z "$MOUNT_POINT" ]; then
        echo "❌ Could not find mounted DMG"
        exit 1
    fi
    echo "✅ Found DMG mounted at: $MOUNT_POINT"
}

# Create directories if they don't exist
mkdir -p "$MOUNT_POINT/.gradle"
mkdir -p "$MOUNT_POINT/android-builds"
mkdir -p "$MOUNT_POINT/flutter-builds"
mkdir -p "$MOUNT_POINT/global-gradle"

# Remove existing directories/symlinks and create new symlinks
echo "🔗 Creating symlinks..."

cd "$PROJECT_ROOT"

# Android .gradle
if [ -d "android/.gradle" ] && [ ! -L "android/.gradle" ]; then
    echo "📦 Backing up existing android/.gradle..."
    mv android/.gradle android/.gradle.backup
fi
rm -f android/.gradle
ln -sf "$MOUNT_POINT/.gradle" android/.gradle

# Android build
if [ -d "android/build" ] && [ ! -L "android/build" ]; then
    echo "📦 Backing up existing android/build..."
    mv android/build android/build.backup
fi
rm -f android/build
ln -sf "$MOUNT_POINT/android-builds" android/build

# Flutter build
if [ -d "build" ] && [ ! -L "build" ]; then
    echo "📦 Backing up existing build..."
    mv build build.backup
fi
rm -f build
ln -sf "$MOUNT_POINT/flutter-builds" build

# Global Gradle cache (optional)
if [ -d "$HOME/.gradle" ] && [ ! -L "$HOME/.gradle" ]; then
    echo "📦 Backing up global .gradle..."
    mv "$HOME/.gradle" "$HOME/.gradle.backup"
    mkdir -p "$MOUNT_POINT/global-gradle"
    ln -sf "$MOUNT_POINT/global-gradle" "$HOME/.gradle"
fi

echo "✅ Symlinks created successfully!"
echo ""
echo "📋 Symlinks:"
echo "   android/.gradle -> $MOUNT_POINT/.gradle"
echo "   android/build -> $MOUNT_POINT/android-builds"
echo "   build -> $MOUNT_POINT/flutter-builds"
if [ -L "$HOME/.gradle" ]; then
    echo "   ~/.gradle -> $MOUNT_POINT/global-gradle"
fi

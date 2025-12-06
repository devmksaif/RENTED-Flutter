# Android Builds DMG Setup - Complete Guide

## ✅ Setup Complete!

A 20GB sparse DMG has been created on your SSD and symlinks are configured.

---

## 📦 What Was Created

### DMG File
- **Location**: `/Volumes/Untitled/android-builds.dmg.sparseimage`
- **Size**: 20GB (sparse - grows as needed)
- **Format**: APFS
- **Volume Name**: `android-builds`
- **Mount Point**: `/Volumes/android-builds`

### Symlinks Created
- `android/.gradle` → `/Volumes/android-builds/.gradle`
- `android/build` → `/Volumes/android-builds/android-builds`
- `build/` → `/Volumes/android-builds/flutter-builds`
- `~/.gradle` → `/Volumes/android-builds/global-gradle` (optional)

---

## 🔧 Manual Mount/Unmount

### Mount DMG
```bash
hdiutil attach /Volumes/Untitled/android-builds.dmg.sparseimage -mountpoint /Volumes/android-builds
```

Or use the helper script:
```bash
/Users/Apple/StudioProjects/RENTED/mount_android_builds.sh
```

### Unmount DMG
```bash
hdiutil detach /Volumes/android-builds
```

---

## 🔄 Auto-Mount on Boot

A LaunchAgent has been created at:
```
~/Library/LaunchAgents/com.android.builds.mount.plist
```

**Note**: The LaunchAgent may need to be loaded manually the first time:
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.android.builds.mount.plist
```

Or use the modern approach:
```bash
launchctl load ~/Library/LaunchAgents/com.android.builds.mount.plist
```

---

## 📋 Verify Setup

Check if symlinks are working:
```bash
cd /Users/Apple/StudioProjects/RENTED
ls -la android/.gradle android/build build
```

All should show as symlinks pointing to `/Volumes/android-builds/...`

---

## 🧹 Clean Up (if needed)

If you need to remove the setup:

1. **Unmount DMG**:
   ```bash
   hdiutil detach /Volumes/android-builds
   ```

2. **Remove symlinks**:
   ```bash
   cd /Users/Apple/StudioProjects/RENTED
   rm android/.gradle android/build build
   ```

3. **Restore backups** (if they exist):
   ```bash
   mv android/.gradle.backup android/.gradle
   mv android/build.backup android/build
   mv build.backup build
   ```

4. **Remove LaunchAgent**:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.android.builds.mount.plist
   rm ~/Library/LaunchAgents/com.android.builds.mount.plist
   ```

---

## 💡 Benefits

✅ **Saves Internal Storage**: All Android build artifacts are stored on SSD
✅ **Faster Builds**: SSD is typically faster than internal storage
✅ **Easy Cleanup**: Just unmount the DMG to free up space
✅ **Persistent**: DMG file persists on SSD, can be remounted anytime
✅ **Automatic**: LaunchAgent mounts it on boot

---

## 🐛 Troubleshooting

### DMG won't mount
```bash
# Check if SSD is mounted
ls /Volumes/Untitled

# Check DMG file exists
ls -lh /Volumes/Untitled/android-builds.dmg.sparseimage

# Try mounting manually
hdiutil attach /Volumes/Untitled/android-builds.dmg.sparseimage
```

### Symlinks broken
```bash
# Re-run the mount script
/Users/Apple/StudioProjects/RENTED/mount_android_builds.sh
```

### LaunchAgent not working
```bash
# Check logs
cat /tmp/android-builds-mount.log
cat /tmp/android-builds-mount.error.log

# Reload agent
launchctl unload ~/Library/LaunchAgents/com.android.builds.mount.plist
launchctl load ~/Library/LaunchAgents/com.android.builds.mount.plist
```

---

## 📊 Storage Usage

Check DMG usage:
```bash
df -h /Volumes/android-builds
```

The DMG will grow as needed (sparse format), up to 20GB.

---

## ✅ Firebase Package Status

The `kreait/firebase-php` package is:
- ✅ Installed (version 7.24.0)
- ✅ Factory class available: `Kreait\Firebase\Factory`
- ✅ Autoload working correctly

If you see "NOT found" errors, it's likely an IDE cache issue. Try:
1. Restart your IDE/editor
2. Run `composer dump-autoload` in Laravel directory
3. Clear IDE caches

The package is correctly installed and working.

#!/bin/bash

echo "🔄 Installing dependencies..."
flutter pub get

echo "🎨 Generating app icons from assets/images/rented.png..."
dart run flutter_launcher_icons

echo "✅ Icon generation complete!"
echo ""
echo "📱 Next steps:"
echo "1. For Android: Uninstall the app from your device/emulator, then rebuild:"
echo "   flutter clean && flutter build apk"
echo ""
echo "2. For iOS: Clean build folder in Xcode, then rebuild"
echo ""
echo "3. If icon still doesn't show, try:"
echo "   - Uninstall the app completely"
echo "   - Restart your device/emulator"
echo "   - Rebuild and reinstall"

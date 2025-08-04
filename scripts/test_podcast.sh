#!/bin/bash

# Podcast Creation Test Script
# Bu script, podcast oluşturma sürecindeki hataları test eder

echo "🎧 Podcast Creation Test Script"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed"
    exit 1
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not in a Flutter project directory"
    exit 1
fi

# Check environment variables
echo "🔍 Checking environment variables..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    source .env
else
    echo "⚠️  .env file not found"
fi

# Check Firebase configuration
echo ""
echo "🔥 Checking Firebase configuration..."
if [ -f "android/app/google-services.json" ]; then
    echo "✅ Google Services JSON exists"
else
    echo "❌ Google Services JSON not found"
    echo "Please add google-services.json to android/app/"
fi

# Check iOS configuration
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist exists"
else
    echo "❌ GoogleService-Info.plist not found"
    echo "Please add GoogleService-Info.plist to ios/Runner/"
fi

# Run Flutter doctor
echo ""
echo "🏥 Running Flutter doctor..."
flutter doctor

# Clean and get dependencies
echo ""
echo "🧹 Cleaning project..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

# Run tests
echo ""
echo "🧪 Running tests..."
flutter test

# Build for debugging
echo ""
echo "🔨 Building for debugging..."
flutter build apk --debug

echo ""
echo "✅ Test completed!"
echo ""
echo "📋 Next steps:"
echo "1. Check Firebase Console for Storage rules"
echo "2. Verify Firestore security rules"
echo "3. Test podcast creation in the app"
echo "4. Check logs for any remaining errors" 
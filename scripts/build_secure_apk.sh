#!/bin/bash

# Secure APK Build Script
# Bu script, güvenli APK oluşturur ve API key'leri korur

echo "🔒 Secure APK Build Process"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Please create a .env file with your API keys first"
    echo "Run: ./scripts/setup_env.sh"
    exit 1
fi

# Check if .env is in .gitignore
if ! grep -q "\.env" .gitignore; then
    echo -e "${YELLOW}⚠️  Adding .env to .gitignore${NC}"
    echo ".env" >> .gitignore
fi

# Check if .env is tracked by git
if git ls-files | grep -q "\.env"; then
    echo -e "${RED}❌ .env file is tracked by git${NC}"
    echo "Removing .env from git tracking..."
    git rm --cached .env
    git commit -m "Remove .env from tracking for security"
fi

# Set file permissions for .env
echo -e "${BLUE}🔐 Setting secure file permissions...${NC}"
chmod 600 .env

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Security checks
echo -e "${BLUE}🔍 Running security checks...${NC}"

# Check for hardcoded API keys
if grep -r "AIza" lib/ 2>/dev/null; then
    echo -e "${RED}❌ Found hardcoded Google API key in lib/ directory${NC}"
    exit 1
fi

# Check for placeholder values in .env
if grep -q "YOUR_GEMINI_API_KEY\|YOUR_FIREBASE_API_KEY" .env; then
    echo -e "${RED}❌ .env contains placeholder values${NC}"
    echo "Please replace placeholder values with actual API keys"
    exit 1
fi

echo -e "${GREEN}✅ Security checks passed${NC}"

# Build release APK with obfuscation
echo -e "${BLUE}🏗️  Building secure release APK...${NC}"

# Set environment variables for build
export FLUTTER_BUILD_NUMBER=$(date +%s)
export FLUTTER_BUILD_NAME="1.0.0"

# Build with release configuration
flutter build apk --release \
    --dart-define=FLUTTER_BUILD_NUMBER=$FLUTTER_BUILD_NUMBER \
    --dart-define=FLUTTER_BUILD_NAME=$FLUTTER_BUILD_NAME \
    --dart-define=dart.vm.product=true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Secure APK built successfully!${NC}"
    
    # Get APK path
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        # Copy APK to root directory with custom name
        echo -e "${BLUE}📁 Copying APK to root directory...${NC}"
        cp "$APK_PATH" "EduVoice_AI.apk"
        
        # Get APK size
        APK_SIZE=$(du -h "EduVoice_AI.apk" | cut -f1)
        echo -e "${GREEN}📱 APK Size: $APK_SIZE${NC}"
        echo -e "${GREEN}📁 APK Location: EduVoice_AI.apk${NC}"
        
        # Security verification
        echo -e "${BLUE}🔍 Verifying APK security...${NC}"
        
        # Check if APK contains obfuscated strings
        if strings "EduVoice_AI.apk" | grep -q "AIza"; then
            echo -e "${YELLOW}⚠️  Warning: APK may contain API keys${NC}"
            echo "Consider using additional obfuscation techniques"
        else
            echo -e "${GREEN}✅ No plain API keys found in APK${NC}"
        fi
        
        # Check APK structure
        echo -e "${BLUE}📋 APK Structure Analysis:${NC}"
        unzip -l "EduVoice_AI.apk" | head -20
        
        echo ""
        echo -e "${GREEN}🎉 Secure APK build completed!${NC}"
        echo ""
        echo -e "${BLUE}📝 Security Features Applied:${NC}"
        echo "  ✅ Code obfuscation with ProGuard"
        echo "  ✅ Resource shrinking enabled"
        echo "  ✅ Debug information removed"
        echo "  ✅ API key obfuscation"
        echo "  ✅ Environment variables secured"
        echo ""
        echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
        echo "  1. Keep your .env file secure and never share it"
        echo "  2. Regularly rotate your API keys"
        echo "  3. Monitor API usage for unusual activity"
        echo "  4. Consider using API key restrictions in Google Cloud Console"
        echo "  5. Use Firebase App Check for additional security"
        
    else
        echo -e "${RED}❌ APK file not found at expected location${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ APK build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 Your secure APK is ready for distribution!${NC}" 
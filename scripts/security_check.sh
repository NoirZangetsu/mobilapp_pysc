#!/bin/bash

# API Key Security Check Script
# Bu script, API keylerin güvenliğini kontrol eder

echo "🔒 API Key Security Check"
echo "========================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Please create a .env file with your API keys"
    exit 1
fi

# Check if .env is in .gitignore
if grep -q "\.env" .gitignore; then
    echo -e "${GREEN}✅ .env is in .gitignore${NC}"
else
    echo -e "${RED}❌ .env is NOT in .gitignore${NC}"
    echo "Add '.env' to your .gitignore file"
fi

# Check if .env is tracked by git
if git ls-files | grep -q "\.env"; then
    echo -e "${RED}❌ .env file is tracked by git${NC}"
    echo "Remove .env from git tracking: git rm --cached .env"
else
    echo -e "${GREEN}✅ .env file is not tracked by git${NC}"
fi

# Check for hardcoded API keys in code
echo ""
echo "🔍 Checking for hardcoded API keys..."

# Check for actual API keys in Dart files
if grep -r "AIza" lib/ 2>/dev/null; then
    echo -e "${RED}❌ Found hardcoded Google API key${NC}"
else
    echo -e "${GREEN}✅ No hardcoded Google API keys found${NC}"
fi

# Check for placeholder values
if grep -r "YOUR_GEMINI_API_KEY\|YOUR_FIREBASE_API_KEY" lib/ 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Found placeholder API keys in code${NC}"
    echo "This is expected for development, but make sure real keys are in .env"
else
    echo -e "${GREEN}✅ No placeholder API keys found in code${NC}"
fi

# Check Firebase configuration files
echo ""
echo "🔥 Checking Firebase configuration..."

# Check if google-services.json exists
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json exists${NC}"
    
    # Check if it's tracked by git
    if git ls-files | grep -q "google-services.json"; then
        echo -e "${RED}❌ google-services.json is tracked by git${NC}"
        echo "Remove it from tracking: git rm --cached android/app/google-services.json"
    else
        echo -e "${GREEN}✅ google-services.json is not tracked by git${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  google-services.json not found${NC}"
    echo "Add your Firebase configuration file"
fi

# Check if GoogleService-Info.plist exists
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist exists${NC}"
    
    # Check if it's tracked by git
    if git ls-files | grep -q "GoogleService-Info.plist"; then
        echo -e "${RED}❌ GoogleService-Info.plist is tracked by git${NC}"
        echo "Remove it from tracking: git rm --cached ios/Runner/GoogleService-Info.plist"
    else
        echo -e "${GREEN}✅ GoogleService-Info.plist is not tracked by git${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist not found${NC}"
    echo "Add your Firebase configuration file"
fi

# Check for firebase_options.dart
if [ -f "lib/firebase_options.dart" ]; then
    echo -e "${GREEN}✅ firebase_options.dart exists${NC}"
    
    # Check if it contains actual API keys
    if grep -q "AIza" lib/firebase_options.dart; then
        echo -e "${RED}❌ firebase_options.dart contains actual API keys${NC}"
        echo "This file should be generated and not contain real keys"
    else
        echo -e "${GREEN}✅ firebase_options.dart looks safe${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  firebase_options.dart not found${NC}"
fi

# Check .env file permissions
echo ""
echo "🔐 Checking file permissions..."

if [ -f ".env" ]; then
    PERMS=$(stat -f "%Lp" .env 2>/dev/null || stat -c "%a" .env 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo -e "${GREEN}✅ .env file has correct permissions (600)${NC}"
    else
        echo -e "${YELLOW}⚠️  .env file permissions: $PERMS${NC}"
        echo "Consider setting permissions to 600: chmod 600 .env"
    fi
fi

# Check for environment variables in .env
echo ""
echo "📋 Checking .env file content..."

if [ -f ".env" ]; then
    # Check if required variables exist
    REQUIRED_VARS=("GEMINI_API_KEY" "FIREBASE_API_KEY" "FIREBASE_APP_ID" "FIREBASE_PROJECT_ID")
    
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var=" .env; then
            echo -e "${GREEN}✅ $var is configured${NC}"
        else
            echo -e "${RED}❌ $var is missing${NC}"
        fi
    done
    
    # Check for placeholder values
    if grep -q "YOUR_GEMINI_API_KEY\|YOUR_FIREBASE_API_KEY" .env; then
        echo -e "${RED}❌ .env contains placeholder values${NC}"
        echo "Replace placeholder values with actual API keys"
    else
        echo -e "${GREEN}✅ .env contains actual values (not placeholders)${NC}"
    fi
fi

echo ""
echo "🔒 Security Summary:"
echo "==================="

# Count issues
ISSUES=0
if ! grep -q "\.env" .gitignore; then ((ISSUES++)); fi
if git ls-files | grep -q "\.env"; then ((ISSUES++)); fi
if [ -f ".env" ] && grep -q "YOUR_GEMINI_API_KEY\|YOUR_FIREBASE_API_KEY" .env; then ((ISSUES++)); fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ All security checks passed!${NC}"
else
    echo -e "${RED}❌ Found $ISSUES security issue(s)${NC}"
    echo "Please fix the issues above before deploying"
fi

echo ""
echo "📝 Recommendations:"
echo "1. Keep .env file secure and never commit it"
echo "2. Use environment variables for all API keys"
echo "3. Set proper file permissions (600 for .env)"
echo "4. Regularly rotate your API keys"
echo "5. Monitor API usage for unusual activity" 
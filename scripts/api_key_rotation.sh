#!/bin/bash

# API Key Rotation and Security Script
# Bu script, API key'lerin güvenliğini sağlar ve rotasyon yapar

echo "🔄 API Key Security and Rotation"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check API key security
check_api_security() {
    echo -e "${BLUE}🔍 Checking API Key Security...${NC}"
    
    if [ ! -f ".env" ]; then
        echo -e "${RED}❌ .env file not found${NC}"
        return 1
    fi
    
    # Check file permissions
    PERMS=$(stat -f "%Lp" .env 2>/dev/null || stat -c "%a" .env 2>/dev/null)
    if [ "$PERMS" != "600" ]; then
        echo -e "${YELLOW}⚠️  .env file permissions: $PERMS (should be 600)${NC}"
        chmod 600 .env
        echo -e "${GREEN}✅ Fixed .env permissions${NC}"
    else
        echo -e "${GREEN}✅ .env file has correct permissions${NC}"
    fi
    
    # Check for placeholder values
    if grep -q "YOUR_GEMINI_API_KEY\|YOUR_FIREBASE_API_KEY" .env; then
        echo -e "${RED}❌ .env contains placeholder values${NC}"
        return 1
    else
        echo -e "${GREEN}✅ .env contains actual API keys${NC}"
    fi
    
    # Check if .env is in .gitignore
    if grep -q "\.env" .gitignore; then
        echo -e "${GREEN}✅ .env is in .gitignore${NC}"
    else
        echo -e "${RED}❌ .env is NOT in .gitignore${NC}"
        echo ".env" >> .gitignore
        echo -e "${GREEN}✅ Added .env to .gitignore${NC}"
    fi
    
    return 0
}

# Function to rotate API keys
rotate_api_keys() {
    echo -e "${BLUE}🔄 API Key Rotation Process${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠️  This will invalidate your current API keys${NC}"
    read -p "Are you sure you want to rotate API keys? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}📝 Please provide new API keys:${NC}"
        echo ""
        
        # Backup current .env
        if [ -f ".env" ]; then
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${GREEN}✅ Backed up current .env file${NC}"
        fi
        
        # Get new API keys
        read -p "New Gemini API Key: " NEW_GEMINI_KEY
        read -p "New Google TTS API Key: " NEW_TTS_KEY
        read -p "New Firebase API Key: " NEW_FIREBASE_KEY
        read -p "Firebase Project ID: " FIREBASE_PROJECT_ID
        read -p "Firebase App ID: " FIREBASE_APP_ID
        read -p "Firebase Sender ID: " FIREBASE_SENDER_ID
        read -p "Firebase Storage Bucket: " FIREBASE_STORAGE_BUCKET
        
        # Create new .env file
        cat > .env << EOF
# Dinleyen Zeka Environment Variables
# Generated on $(date)

# Gemini API Configuration
GEMINI_API_KEY=$NEW_GEMINI_KEY

# Google TTS API Configuration
GOOGLE_TTS_API_KEY=$NEW_TTS_KEY

# Firebase Configuration
FIREBASE_API_KEY=$NEW_FIREBASE_KEY
FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
FIREBASE_APP_ID=$FIREBASE_APP_ID
FIREBASE_SENDER_ID=$FIREBASE_SENDER_ID
FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
EOF
        
        # Set secure permissions
        chmod 600 .env
        
        echo -e "${GREEN}✅ API keys rotated successfully${NC}"
        echo -e "${YELLOW}⚠️  Remember to update your Google Cloud Console and Firebase Console${NC}"
        
        # Clean build cache
        echo -e "${BLUE}🧹 Cleaning build cache...${NC}"
        flutter clean
        flutter pub get
        
        echo -e "${GREEN}✅ Ready to build new secure APK${NC}"
    else
        echo -e "${YELLOW}❌ API key rotation cancelled${NC}"
    fi
}

# Function to monitor API usage
monitor_api_usage() {
    echo -e "${BLUE}📊 API Usage Monitoring${NC}"
    echo ""
    
    if [ ! -f ".env" ]; then
        echo -e "${RED}❌ .env file not found${NC}"
        return 1
    fi
    
    # Extract API keys for monitoring
    GEMINI_KEY=$(grep "GEMINI_API_KEY" .env | cut -d'=' -f2)
    FIREBASE_KEY=$(grep "FIREBASE_API_KEY" .env | cut -d'=' -f2)
    
    echo -e "${BLUE}🔍 Checking API key formats...${NC}"
    
    if [[ $GEMINI_KEY == AIza* ]]; then
        echo -e "${GREEN}✅ Gemini API key format is correct${NC}"
    else
        echo -e "${YELLOW}⚠️  Gemini API key format may be incorrect${NC}"
    fi
    
    if [[ $FIREBASE_KEY == AIza* ]]; then
        echo -e "${GREEN}✅ Firebase API key format is correct${NC}"
    else
        echo -e "${YELLOW}⚠️  Firebase API key format may be incorrect${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Security Recommendations:${NC}"
    echo "1. Set API key restrictions in Google Cloud Console"
    echo "2. Enable Firebase App Check"
    echo "3. Monitor usage in Google Cloud Console"
    echo "4. Set up billing alerts"
    echo "5. Regularly rotate API keys"
}

# Function to generate security report
generate_security_report() {
    echo -e "${BLUE}📋 Security Report Generation${NC}"
    echo ""
    
    REPORT_FILE="security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "API Key Security Report"
        echo "Generated: $(date)"
        echo "========================"
        echo ""
        
        # Check .env file
        if [ -f ".env" ]; then
            echo "✅ .env file exists"
            PERMS=$(stat -f "%Lp" .env 2>/dev/null || stat -c "%a" .env 2>/dev/null)
            echo "📁 .env permissions: $PERMS"
        else
            echo "❌ .env file missing"
        fi
        
        # Check .gitignore
        if grep -q "\.env" .gitignore; then
            echo "✅ .env in .gitignore"
        else
            echo "❌ .env not in .gitignore"
        fi
        
        # Check for hardcoded keys
        if grep -r "AIza" lib/ 2>/dev/null; then
            echo "❌ Hardcoded API keys found in lib/"
        else
            echo "✅ No hardcoded API keys in lib/"
        fi
        
        # Check ProGuard configuration
        if [ -f "android/app/proguard-rules.pro" ]; then
            echo "✅ ProGuard rules configured"
        else
            echo "❌ ProGuard rules missing"
        fi
        
        echo ""
        echo "Security Score:"
        SCORE=0
        if [ -f ".env" ]; then ((SCORE+=20)); fi
        if grep -q "\.env" .gitignore; then ((SCORE+=20)); fi
        if [ ! -z "$PERMS" ] && [ "$PERMS" = "600" ]; then ((SCORE+=20)); fi
        if ! grep -r "AIza" lib/ 2>/dev/null; then ((SCORE+=20)); fi
        if [ -f "android/app/proguard-rules.pro" ]; then ((SCORE+=20)); fi
        
        echo "Overall Security Score: $SCORE/100"
        
        if [ $SCORE -eq 100 ]; then
            echo "🎉 Excellent security configuration!"
        elif [ $SCORE -ge 80 ]; then
            echo "✅ Good security configuration"
        elif [ $SCORE -ge 60 ]; then
            echo "⚠️  Moderate security configuration"
        else
            echo "❌ Poor security configuration"
        fi
        
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✅ Security report saved to: $REPORT_FILE${NC}"
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}🔒 API Key Security Menu${NC}"
    echo "1. Check API Key Security"
    echo "2. Rotate API Keys"
    echo "3. Monitor API Usage"
    echo "4. Generate Security Report"
    echo "5. Build Secure APK"
    echo "6. Exit"
    echo ""
    read -p "Select an option (1-6): " choice
    
    case $choice in
        1)
            check_api_security
            ;;
        2)
            rotate_api_keys
            ;;
        3)
            monitor_api_usage
            ;;
        4)
            generate_security_report
            ;;
        5)
            echo -e "${BLUE}🏗️  Building secure APK...${NC}"
            ./scripts/build_secure_apk.sh
            ;;
        6)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            ;;
    esac
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if .env exists
    if [ ! -f ".env" ]; then
        echo -e "${RED}❌ .env file not found${NC}"
        echo "Please run ./scripts/setup_env.sh first"
        exit 1
    fi
    
    # Run security check first
    check_api_security
    
    # Show menu
    while true; do
        show_menu
        echo ""
        read -p "Press Enter to continue..."
    done
fi 
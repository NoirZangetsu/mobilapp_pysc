#!/bin/bash

# Dinleyen Zeka - Environment Variables Setup Script
# Bu script, uygulama için gerekli environment variable'ları ayarlar

echo "🚀 Dinleyen Zeka - Environment Variables Setup"
echo "=============================================="
echo ""

# Gemini API Key
echo "🤖 Gemini API Key ayarlanıyor..."
read -p "Gemini API Key'inizi girin: " GEMINI_API_KEY

if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  Gemini API Key boş bırakıldı. Uygulama Gemini özelliklerini kullanamayacak."
else
    echo "✅ Gemini API Key ayarlandı"
fi

# Firebase Configuration
echo ""
echo "🔥 Firebase yapılandırması ayarlanıyor..."

read -p "Firebase API Key'inizi girin: " FIREBASE_API_KEY
read -p "Firebase App ID'nizi girin: " FIREBASE_APP_ID
read -p "Firebase Project ID'nizi girin: " FIREBASE_PROJECT_ID
read -p "Firebase Sender ID'nizi girin: " FIREBASE_SENDER_ID
read -p "Firebase Storage Bucket'ınızı girin: " FIREBASE_STORAGE_BUCKET

# Environment file oluştur
ENV_FILE=".env"

echo "# Dinleyen Zeka Environment Variables" > $ENV_FILE
echo "# Bu dosya otomatik olarak oluşturulmuştur" >> $ENV_FILE
echo "" >> $ENV_FILE

# Gemini
if [ ! -z "$GEMINI_API_KEY" ]; then
    echo "export GEMINI_API_KEY=\"$GEMINI_API_KEY\"" >> $ENV_FILE
fi

# Firebase
if [ ! -z "$FIREBASE_API_KEY" ]; then
    echo "export FIREBASE_API_KEY=\"$FIREBASE_API_KEY\"" >> $ENV_FILE
fi

if [ ! -z "$FIREBASE_APP_ID" ]; then
    echo "export FIREBASE_APP_ID=\"$FIREBASE_APP_ID\"" >> $ENV_FILE
fi

if [ ! -z "$FIREBASE_PROJECT_ID" ]; then
    echo "export FIREBASE_PROJECT_ID=\"$FIREBASE_PROJECT_ID\"" >> $ENV_FILE
fi

if [ ! -z "$FIREBASE_SENDER_ID" ]; then
    echo "export FIREBASE_SENDER_ID=\"$FIREBASE_SENDER_ID\"" >> $ENV_FILE
fi

if [ ! -z "$FIREBASE_STORAGE_BUCKET" ]; then
    echo "export FIREBASE_STORAGE_BUCKET=\"$FIREBASE_STORAGE_BUCKET\"" >> $ENV_FILE
fi

echo ""
echo "✅ Environment variables .env dosyasına kaydedildi"
echo ""
echo "📝 Kullanım:"
echo "1. Environment variables'ları yüklemek için: source .env"
echo "2. Uygulamayı çalıştırmak için: flutter run"
echo ""
echo "🔒 Güvenlik: .env dosyasını .gitignore'a eklediğinizden emin olun!"
echo ""
echo "📋 Ayarlanan değişkenler:"
if [ ! -z "$GEMINI_API_KEY" ]; then
    echo "  ✅ GEMINI_API_KEY"
else
    echo "  ❌ GEMINI_API_KEY (ayarlanmadı)"
fi

if [ ! -z "$FIREBASE_API_KEY" ] && [ ! -z "$FIREBASE_APP_ID" ] && [ ! -z "$FIREBASE_PROJECT_ID" ]; then
    echo "  ✅ Firebase yapılandırması"
else
    echo "  ❌ Firebase yapılandırması (eksik)"
fi

echo ""
echo "🎉 Kurulum tamamlandı!" 
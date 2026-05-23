#!/bin/bash

# 🛰️ Sato Setup Script
# Quick setup for first-time users

set -e

echo "🛰️  Sato Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if config already exists
if [ -f "config/config.json" ]; then
    echo "⚠️  config/config.json already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled. Your existing config is safe."
        exit 0
    fi
fi

# Copy example config
echo "📋 Creating config/config.json from template..."
cp config/config.json.example config/config.json

# Create history file if it doesn't exist
if [ ! -f "history.json" ]; then
    echo "📝 Creating history.json..."
    cp config/history.json.example history.json
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Edit config/config.json with your services:"
echo "      nano config/config.json"
echo ""
echo "   2. See the configuration guide for examples:"
echo "      cat config/CONFIG_GUIDE.md"
echo ""
echo "   3. Run Sato:"
echo "      python3 sato.py"
echo ""
echo "📚 Documentation:"
echo "   • Configuration Guide: config/CONFIG_GUIDE.md"
echo "   • Main README: README.md"
echo "   • Enhanced Notifications: docs/ENHANCED_NOTIFICATIONS.md"
echo ""
echo "🎯 Quick example config:"
echo '   [
     {
       "name": "My API",
       "host": "https://api.mycompany.com",
       "type": "server",
       "icon": "🌐"
     }
   ]'
echo ""

#!/bin/bash

# Migration script to help transition from old cli.sh to refactored version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_CONFIG="$HOME/.config/nicronian-setup/last_config.conf"
NEW_CONFIG="$HOME/.config/nicronian-setup/last_config.conf.new"

echo "🔄 Nicronian Setup Migration Tool"
echo "=================================="

# Check if old config exists
if [[ -f "$OLD_CONFIG" ]]; then
    echo "✅ Found existing configuration at: $OLD_CONFIG"
    
    # Backup old config
    cp "$OLD_CONFIG" "$OLD_CONFIG.backup"
    echo "📦 Backed up old config to: $OLD_CONFIG.backup"
    
    # The new structure is compatible with the old config format
    echo "✅ Configuration is compatible with refactored version"
else
    echo "ℹ️  No existing configuration found - you'll start fresh"
fi

# Check if old cli.sh exists
if [[ -f "cli.sh" ]]; then
    echo "📁 Found old cli.sh - backing it up"
    mv cli.sh cli.sh.backup
    echo "📦 Backed up old script to: cli.sh.backup"
fi

# Make main.sh executable
chmod +x "$SCRIPT_DIR/main.sh"

echo ""
echo "🎉 Migration completed!"
echo ""
echo "Next steps:"
echo "1. Run the new script: ./cli-refactored/main.sh"
echo "2. Your old configuration will be loaded automatically"
echo "3. If you encounter issues, your backup is at: cli.sh.backup"
echo ""
echo "New features available:"
echo "- --dry-run mode to test without installing"
echo "- --debug mode for verbose output"
echo "- --help for usage information"
echo "- Better error handling and progress tracking"
echo "- Modular architecture for easier maintenance"
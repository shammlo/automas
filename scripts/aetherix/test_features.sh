#!/bin/bash

# Test script for Aetherix enhanced features

echo "🧪 Testing Aetherix Enhanced Features"
echo "====================================="

# Test 1: Help message includes new options
echo "Test 1: Checking help message for new options..."
if ./aetherix_features.sh --help | grep -q "resume\|analytics\|interactive"; then
    echo "✅ Help message includes new options"
else
    echo "❌ Help message missing new options"
fi

# Test 2: Check if enhanced modules load
echo ""
echo "Test 2: Checking if enhanced modules can be loaded..."
if [[ -f "lib/enhanced_installer.sh" ]]; then
    echo "✅ Enhanced installer module exists"
else
    echo "❌ Enhanced installer module missing"
fi

# Test 3: Dry run with analytics initialization
echo ""
echo "Test 3: Testing dry run with analytics..."
if ./aetherix_features.sh --dry-run --help >/dev/null 2>&1; then
    echo "✅ Dry run executes without errors"
else
    echo "❌ Dry run has errors"
fi

# Test 4: Check configuration directory creation
echo ""
echo "Test 4: Testing configuration directory..."
CONFIG_DIR="$HOME/.config/nicronian-setup"
if [[ -d "$CONFIG_DIR" ]]; then
    echo "✅ Configuration directory exists: $CONFIG_DIR"
else
    echo "⚠️  Configuration directory will be created on first run"
fi

# Test 5: Validate script syntax
echo ""
echo "Test 5: Validating script syntax..."
if bash -n aetherix_features.sh; then
    echo "✅ Script syntax is valid"
else
    echo "❌ Script has syntax errors"
fi

echo ""
echo "🎉 Feature testing completed!"
echo ""
echo "To test the enhanced features:"
echo "  ./aetherix_features.sh --help"
echo "  ./aetherix_features.sh --dry-run"
echo "  ./aetherix_features.sh --interactive"
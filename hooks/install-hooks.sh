#!/bin/bash

# install-hooks.sh - Quick setup script for Git hooks

set -e

echo "🔧 Installing Git hooks for py-claude-marketplace..."

# Check if we're in the right directory
if [ ! -f "py-plugin/.claude-plugin/plugin.json" ]; then
    echo "❌ Error: This script must be run from the repository root"
    echo "   Make sure you're in the py-claude-marketplace directory"
    exit 1
fi

# Check if hooks directory exists
if [ ! -d "hooks" ]; then
    echo "❌ Error: hooks/ directory not found"
    exit 1
fi

# Install pre-commit hook
echo "📋 Installing pre-commit hook..."
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Verify installation
if [ -x ".git/hooks/pre-commit" ]; then
    echo "✅ Pre-commit hook installed successfully!"
    echo ""
    echo "🎉 Automatic version bumping is now active!"
    echo ""
    echo "💡 How to test:"
    echo "   1. Make changes to py-plugin/ files"
    echo "   2. git add and git commit"
    echo "   3. Watch version bump automatically"
    echo ""
    echo "🚫 To skip version bump, add '[skip version bump]' to commit message"
else
    echo "❌ Hook installation failed"
    exit 1
fi
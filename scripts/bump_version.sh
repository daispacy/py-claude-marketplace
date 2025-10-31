#!/bin/bash

# bump_version.sh - Simple shell script to bump version in plugin.json

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and plugin.json path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_JSON="$REPO_ROOT/py-plugin/.claude-plugin/plugin.json"

# Function to display usage
usage() {
    echo "Usage: $0 [major|minor|patch]"
    echo "  major: 1.0.3 -> 2.0.0"
    echo "  minor: 1.0.3 -> 1.1.0"
    echo "  patch: 1.0.3 -> 1.0.4 (default)"
    exit 1
}

# Function to bump version
bump_version() {
    local version="$1"
    local bump_type="$2"
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major="${VERSION_PARTS[0]}"
    local minor="${VERSION_PARTS[1]}"
    local patch="${VERSION_PARTS[2]}"
    
    case "$bump_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch"|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Parse arguments
BUMP_TYPE="patch"
if [ $# -gt 0 ]; then
    case "$1" in
        "major"|"minor"|"patch")
            BUMP_TYPE="$1"
            ;;
        "-h"|"--help")
            usage
            ;;
        *)
            echo -e "${RED}Error: Invalid bump type '$1'${NC}"
            usage
            ;;
    esac
fi

# Check if plugin.json exists
if [ ! -f "$PLUGIN_JSON" ]; then
    echo -e "${RED}Error: plugin.json not found at $PLUGIN_JSON${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(python3 -c "
import json
try:
    with open('$PLUGIN_JSON', 'r') as f:
        data = json.load(f)
    print(data.get('version', '0.0.0'))
except Exception as e:
    print('ERROR:', e, file=sys.stderr)
    exit(1)
")

if [[ "$CURRENT_VERSION" == ERROR* ]]; then
    echo -e "${RED}Error reading current version from plugin.json${NC}"
    exit 1
fi

# Calculate new version
NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$BUMP_TYPE")

echo -e "${YELLOW}Bumping version from $CURRENT_VERSION to $NEW_VERSION (${BUMP_TYPE})${NC}"

# Update plugin.json
python3 -c "
import json
import sys

try:
    with open('$PLUGIN_JSON', 'r') as f:
        data = json.load(f)
    
    data['version'] = '$NEW_VERSION'
    
    with open('$PLUGIN_JSON', 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')
    
    print('Success')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Version successfully bumped to $NEW_VERSION${NC}"
    
    # Ask if user wants to commit the change
    read -p "Do you want to commit this version change? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add "$PLUGIN_JSON"
        git commit -m "Bump version to $NEW_VERSION"
        echo -e "${GREEN}✅ Version change committed${NC}"
    fi
else
    echo -e "${RED}❌ Failed to update version${NC}"
    exit 1
fi
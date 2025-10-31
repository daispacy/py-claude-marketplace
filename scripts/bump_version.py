#!/usr/bin/env python3
"""
Version bumping script for plugin.json
Automatically increments the patch version (e.g., 1.0.3 -> 1.0.4)
"""

import json
import os
import sys
from pathlib import Path

def bump_version(version_str, bump_type='patch'):
    """
    Bump version string based on semantic versioning
    
    Args:
        version_str (str): Current version (e.g., "1.0.3")
        bump_type (str): Type of bump - 'major', 'minor', or 'patch'
    
    Returns:
        str: New version string
    """
    try:
        parts = version_str.split('.')
        major, minor, patch = map(int, parts)
        
        if bump_type == 'major':
            major += 1
            minor = 0
            patch = 0
        elif bump_type == 'minor':
            minor += 1
            patch = 0
        else:  # patch
            patch += 1
            
        return f"{major}.{minor}.{patch}"
    except (ValueError, IndexError) as e:
        print(f"Error parsing version '{version_str}': {e}")
        return None

def update_plugin_json(file_path, bump_type='patch'):
    """
    Update the version in plugin.json
    
    Args:
        file_path (str): Path to plugin.json
        bump_type (str): Type of version bump
    
    Returns:
        tuple: (old_version, new_version) or (None, None) if error
    """
    try:
        # Read current plugin.json
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        current_version = data.get('version', '0.0.0')
        new_version = bump_version(current_version, bump_type)
        
        if not new_version:
            return None, None
        
        # Update version
        data['version'] = new_version
        
        # Write back to file with proper formatting
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add newline at end
        
        return current_version, new_version
        
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found")
        return None, None
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in '{file_path}': {e}")
        return None, None
    except Exception as e:
        print(f"Error updating '{file_path}': {e}")
        return None, None

def main():
    """Main function"""
    # Get script directory and find plugin.json
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    plugin_json_path = repo_root / "py-plugin" / ".claude-plugin" / "plugin.json"
    
    # Parse command line arguments
    bump_type = 'patch'
    if len(sys.argv) > 1:
        if sys.argv[1] in ['major', 'minor', 'patch']:
            bump_type = sys.argv[1]
        else:
            print("Usage: python bump_version.py [major|minor|patch]")
            print("Default: patch")
            sys.exit(1)
    
    # Update version
    old_version, new_version = update_plugin_json(plugin_json_path, bump_type)
    
    if old_version and new_version:
        print(f"Version bumped from {old_version} to {new_version}")
        return 0
    else:
        print("Failed to bump version")
        return 1

if __name__ == "__main__":
    sys.exit(main())
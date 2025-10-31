# Repository Git Hooks

This folder contains reusable Git hooks that can be installed on any computer. The hooks are self-contained and work across different systems without external dependencies.

## 📁 Available Hooks

### `pre-commit` - Automatic Version Bumping
**Self-contained shell script that automatically bumps plugin version on commits.**

**Features:**
- ✅ Pure bash/shell script - no Python required
- ✅ Works on macOS, Linux, and WSL
- ✅ Automatically increments patch version (1.0.7 → 1.0.8)
- ✅ Only runs when plugin-related files are modified
- ✅ Skips merge commits to prevent conflicts
- ✅ Self-contained - no external files needed

## 🚀 Installation

### Quick Setup (New Computer)
```bash
# 1. Clone the repository
git clone <your-repo-url>
cd py-claude-marketplace

# 2. Install the hook (one command!)
cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 3. That's it! Hook is now active
```

### Manual Setup
```bash
# Copy hook from repository to .git/hooks/
cp hooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit

# Verify installation
ls -la .git/hooks/pre-commit
```

### Automatic Setup Script
You can also create an install script:
```bash
#!/bin/bash
# install-hooks.sh
echo "Installing Git hooks..."
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "✅ Pre-commit hook installed successfully!"
```

## 🧪 Testing the Hook

```bash
# Test the hook by making a plugin change
echo "test" > py-plugin/test-file.txt
git add py-plugin/test-file.txt
git commit -m "Test automatic version bump"

# You should see output like:
# Version bumped from 1.0.7 to 1.0.8
```

## 🔧 How It Works

1. **Triggers** - Runs automatically before each commit
2. **Detects Changes** - Only activates when `py-plugin/` files are modified
3. **Parses Version** - Extracts current version from `plugin.json`
4. **Bumps Version** - Increments patch number (X.Y.Z → X.Y.Z+1)
5. **Updates File** - Writes new version back to `plugin.json`
6. **Stages Changes** - Automatically adds updated `plugin.json` to commit

## ⚙️ Customization

### Skip Version Bump
Add `[skip version bump]` to your commit message:
```bash
git commit -m "Update documentation [skip version bump]"
```

### Modify Bump Logic
Edit `hooks/pre-commit` to change:
- Which files trigger the bump
- Version increment logic (patch/minor/major)
- Output messages

## 🔄 Updating Hooks

When hooks are updated in the repository:
```bash
# Re-install the updated hook
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🌍 Cross-Platform Compatibility

**Works on:**
- ✅ macOS (tested)
- ✅ Linux (any distribution)
- ✅ Windows Subsystem for Linux (WSL)
- ✅ Git Bash on Windows

**Requirements:**
- Git (obviously)
- Bash shell
- Standard Unix tools: `grep`, `sed`, `mktemp`

## 🐛 Troubleshooting

### Hook Not Running
```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-commit

# If not executable, fix it:
chmod +x .git/hooks/pre-commit
```

### Version Not Bumping
```bash
# Test hook manually
.git/hooks/pre-commit

# Check if plugin files are staged
git diff --cached --name-only | grep py-plugin
```

### Hook Fails on Commit
```bash
# Check what's wrong by running the hook directly
.git/hooks/pre-commit

# Look for error messages about missing files or permissions
```

## 📋 Repository Structure

```
py-claude-marketplace/
├── hooks/
│   ├── pre-commit           # 🔥 The magic hook
│   └── README.md           # This file
├── .git/hooks/
│   └── pre-commit          # ← Installed copy (not in repo)
└── py-plugin/.claude-plugin/
    └── plugin.json         # ← Gets updated automatically
```

## 🎯 Benefits

1. **Version Controlled** - Hooks are stored in the repository
2. **Team Friendly** - Everyone gets the same hook behavior
3. **Easy Setup** - One command install on new computers
4. **Self-Contained** - No external dependencies or scripts
5. **Portable** - Works across different development environments
6. **Maintainable** - Update once, distribute to all team members
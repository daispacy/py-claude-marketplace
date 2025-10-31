# Automated Version Bumping

This repository includes several automated solutions for version bumping in `plugin.json`.

## Current Version
The current version in `py-plugin/.claude-plugin/plugin.json` is: **1.0.3**

## Available Solutions

### 1. 🔄 Automatic Pre-commit Hook (Recommended)

The pre-commit hook automatically bumps the patch version every time you commit changes to plugin-related files.

**Features:**
- ✅ Automatically increments patch version (1.0.3 → 1.0.4)
- ✅ Only runs when plugin-related files are modified
- ✅ Skips version bump for merge commits
- ✅ Automatically stages the updated `plugin.json`

**Already installed and active!** The hook is located at `.git/hooks/pre-commit`

### 2. 🔧 Manual Version Bump Scripts

#### Python Script
```bash
# Bump patch version (default)
python3 scripts/bump_version.py

# Bump minor version (1.0.3 → 1.1.0)
python3 scripts/bump_version.py minor

# Bump major version (1.0.3 → 2.0.0)
python3 scripts/bump_version.py major
```

#### Shell Script (Interactive)
```bash
# Bump patch version (default)
./scripts/bump_version.sh

# Bump specific version type
./scripts/bump_version.sh minor
./scripts/bump_version.sh major
```

The shell script will ask if you want to commit the changes automatically.

### 3. 🚀 GitHub Actions Workflow

The GitHub Actions workflow provides automated version bumping on push to main branch.

**Triggers:**
- Automatically on push to `main` branch when plugin files change
- Manually via workflow dispatch with version type selection

**Features:**
- Skips if commit message contains `[skip version bump]`
- Creates release tags for major/minor bumps
- Provides summary of version changes

## Usage Examples

### Automatic (Pre-commit Hook)
```bash
# Make some changes to plugin files
git add py-plugin/skills/new-skill/SKILL.md
git commit -m "Add new skill"
# Version automatically bumped from 1.0.3 to 1.0.4
```

### Manual Bump
```bash
# Using Python script
python3 scripts/bump_version.py minor
# Version: 1.0.3 → 1.1.0

# Using shell script (interactive)
./scripts/bump_version.sh patch
# Asks if you want to commit the change
```

### Skip Automatic Bump
```bash
# Add [skip version bump] to your commit message
git commit -m "Update documentation [skip version bump]"
```

## File Structure

```
py-claude-marketplace/
├── .git/hooks/
│   └── pre-commit                    # Automatic pre-commit hook
├── .github/workflows/
│   └── version-bump.yml             # GitHub Actions workflow
├── scripts/
│   ├── bump_version.py              # Python version bump script
│   └── bump_version.sh              # Shell version bump script
└── py-plugin/.claude-plugin/
    └── plugin.json                  # Plugin configuration with version
```

## Semantic Versioning

All scripts follow semantic versioning (semver):

- **Major** (X.0.0): Breaking changes
- **Minor** (X.Y.0): New features, backward compatible
- **Patch** (X.Y.Z): Bug fixes, backward compatible

## Troubleshooting

### Pre-commit Hook Not Working
```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Make it executable if needed
chmod +x .git/hooks/pre-commit
```

### Manual Script Errors
```bash
# Check Python version (requires Python 3.6+)
python3 --version

# Test the script
python3 scripts/bump_version.py --help
```

### GitHub Actions Not Triggering
- Ensure the workflow file is in `.github/workflows/`
- Check that changes are pushed to the `main` branch
- Verify that plugin files are actually modified

## Configuration

You can modify the behavior by editing:

- **Pre-commit hook**: `.git/hooks/pre-commit`
- **Python script**: `scripts/bump_version.py`
- **Shell script**: `scripts/bump_version.sh`
- **GitHub Actions**: `.github/workflows/version-bump.yml`
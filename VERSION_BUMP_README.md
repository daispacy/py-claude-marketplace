# Automated Version Bumping

This repository uses self-contained Git hooks for automatic version bumping in `plugin.json`.

## Current Version
The current version in `py-plugin/.claude-plugin/plugin.json` is: **1.0.5**

## Available Solutions

### 1. 🔄 Self-Contained Pre-commit Hook (Active)

The pre-commit hook automatically bumps the patch version every time you commit changes to plugin-related files.

**Features:**
- ✅ Automatically increments patch version (1.0.5 → 1.0.6)
- ✅ Only runs when plugin-related files are modified
- ✅ Skips version bump for merge commits
- ✅ Automatically stages the updated `plugin.json`
- ✅ **Self-contained** - no external files needed
- ✅ **Cross-platform** - works on any computer

**Currently active!** The hook is located at `.git/hooks/pre-commit`

### 2. 🚀 GitHub Actions Workflow

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
# Version automatically bumped from 1.0.5 to 1.0.6
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
│   ├── pre-commit                   # Self-contained Python hook (ACTIVE)
│   ├── pre-commit-shell            # Self-contained shell hook (BACKUP)
│   └── README.md                    # Hook documentation
├── .github/workflows/
│   └── version-bump.yml             # GitHub Actions workflow
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

### Hook Version Issues
```bash
# Switch to shell version if Python version fails
mv .git/hooks/pre-commit .git/hooks/pre-commit-python
mv .git/hooks/pre-commit-shell .git/hooks/pre-commit

# Switch back to Python version
mv .git/hooks/pre-commit .git/hooks/pre-commit-shell  
mv .git/hooks/pre-commit-python .git/hooks/pre-commit
```

### GitHub Actions Not Triggering
- Ensure the workflow file is in `.github/workflows/`
- Check that changes are pushed to the `main` branch
- Verify that plugin files are actually modified

## Hook Versions

Choose the hook version that works best for your environment:

- **Python Hook** (default): `.git/hooks/pre-commit` - Better JSON handling
- **Shell Hook** (backup): `.git/hooks/pre-commit-shell` - No Python required  
- **GitHub Actions**: `.github/workflows/version-bump.yml` - Remote automation

## Configuration

All version bumping logic is self-contained in the Git hooks. No external configuration needed!
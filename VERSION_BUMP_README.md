# Automated Version Bumping

This repository uses a self-contained Git hook for automatic version bumping in `plugin.json`.

## Current Version
The current version in `py-plugin/.claude-plugin/plugin.json` is: **1.0.6**

## Solution

### 🔄 Self-Contained Pre-commit Hook (Active)

The pre-commit hook automatically bumps the patch version every time you commit changes to plugin-related files.

**Features:**
- ✅ Automatically increments patch version (1.0.6 → 1.0.7)
- ✅ Only runs when plugin-related files are modified
- ✅ Skips version bump for merge commits
- ✅ Automatically stages the updated `plugin.json`
- ✅ **Self-contained** - no external files needed
- ✅ **Cross-platform** - works on any computer
- ✅ **Pure shell script** - no Python dependencies

**Currently active!** The hook is located at `.git/hooks/pre-commit`



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
│   ├── pre-commit                   # Self-contained shell hook (ACTIVE)
│   └── README.md                    # Hook documentation  
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



## Simple & Clean

This setup uses a single self-contained shell script that:

- ✅ Works on any Unix-like system (macOS, Linux, WSL)
- ✅ No Python, Node.js, or other dependencies required
- ✅ No external files or scripts needed
- ✅ No GitHub Actions or cloud services required
- ✅ Just works - copy the hook and go!

## Configuration

All version bumping logic is self-contained in `.git/hooks/pre-commit`. No external configuration needed!
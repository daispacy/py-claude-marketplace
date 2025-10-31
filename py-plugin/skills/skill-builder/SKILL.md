---
name: skill-builder
description: Create new Claude Code agent skills. Guides you through defining skill purpose, triggers, tools, and structure. Use when you want to "create a skill", "build a new skill", "make a skill for", or automate repetitive tasks.
allowed-tools: Read, Write, Glob, Bash
---

# Skill Builder

Help you create new Claude Code agent skills following best practices and proper structure.

## When to Activate

- "create a skill for...", "build a new skill"
- "make a skill that...", "I need a skill to..."
- "generate a skill for..."

## Skill Creation Process

### Step 1: Understand Requirements

Ask user:
1. **What should it do?** (Main task/capability)
2. **When should it activate?** (Trigger keywords/phrases)
3. **What tools needed?** (Read/Write/Bash/All)
4. **What output format?** (Reports/Code/Analysis)

### Step 2: Design the Skill

#### Skill Name
- Lowercase with hyphens (e.g., `todo-finder`, `api-docs-generator`)
- Max 64 characters
- Descriptive and memorable

#### Description (Critical for Discovery!)
**Template**:
```
[Action/Purpose]. [What it does/checks]. Use when [triggers], [patterns], [keywords].
```

**Examples**:
- ✅ "Generate API documentation from Swift code. Extracts function signatures, parameters, comments. Use when working with API files, need to 'document API', 'generate docs', or reviewing public interfaces."
- ❌ "Helps with documentation." (too vague)

**Must include**:
- What it does (specific action)
- What it checks/generates (details)
- Trigger phrases in quotes
- File types or patterns
- Keywords users might say

#### Tool Restrictions

Choose based on needs:
- **Read-only**: `allowed-tools: Read, Grep, Glob` (analysis/review)
- **Read + Write**: `allowed-tools: Read, Write, Grep, Glob` (generation)
- **Full access**: `allowed-tools: Read, Write, Grep, Glob, Bash` (commands/builds)
- **No restrictions**: Omit field (complex workflows)

### Step 3: Structure Content

Every SKILL.md must have:

```markdown
---
name: skill-name
description: [Specific description with triggers]
allowed-tools: Read, Grep, Glob
---

# Skill Title

Brief description of what it does.

## When to Activate

- "trigger phrase 1"
- "trigger phrase 2"
- File types or patterns

## Process

### Step 1: [First Action]
What to do first

### Step 2: [Next Action]
Next steps

### Step 3: [Final Action]
What to output

## Output Format

```markdown
# Report Title
[Template for output]
```

## Quick Reference

**Detailed Examples**: See `examples.md`
**Standards**: [Link to relevant docs]
```

### Step 4: Create Files

**Directory structure**:
```
.claude/skills/skill-name/
├── SKILL.md (required, concise)
├── examples.md (detailed examples)
└── templates/ (optional, code templates)
```

**Create**:
1. `mkdir -p .claude/skills/[skill-name]`
2. Write `SKILL.md` with frontmatter
3. Create `examples.md` for detailed patterns
4. Add templates if needed

### Step 5: Validate

Check:
- [ ] Directory: `.claude/skills/[name]/`
- [ ] File: `SKILL.md` (case-sensitive)
- [ ] Valid YAML frontmatter with `---` delimiters
- [ ] `name:` lowercase with hyphens
- [ ] `description:` specific with triggers
- [ ] Content clear and actionable
- [ ] Examples in separate file

### Step 6: Test

Suggest test phrases based on triggers in description.

Ask: "What skills are available?" to verify it loaded.

## Skill Types

### 1. Code Review
- **Tools**: `Read, Grep, Glob`
- **Output**: Reports with issues/fixes
- **Example**: `security-review`, `performance-check`

### 2. Code Generator
- **Tools**: `Read, Write, Glob`
- **Output**: New files or code
- **Example**: `component-generator`, `test-scaffolder`

### 3. Analyzer
- **Tools**: `Read, Grep, Glob, Bash`
- **Output**: Metrics, reports
- **Example**: `dependency-mapper`, `code-complexity`

### 4. Refactoring
- **Tools**: `Read, Write, Grep, Glob`
- **Output**: Modified files
- **Example**: `extract-method`, `rename-refactor`

### 5. Testing
- **Tools**: `Read, Write, Bash`
- **Output**: Test results/code
- **Example**: `test-runner`, `snapshot-updater`

### 6. Documentation
- **Tools**: `Read, Write, Glob`
- **Output**: Markdown, API docs
- **Example**: `api-docs`, `readme-generator`

## Best Practices

### ✅ DO:
- Use very specific descriptions with clear triggers
- Include file types in description (e.g., "Swift files", ".ts files")
- List keywords users might say
- Provide examples in separate `examples.md`
- Keep SKILL.md concise (under 200 lines)
- Show output format template
- Reference standards/docs
- Use appropriate tool restrictions

### ❌ DON'T:
- Make vague descriptions ("helps with code")
- Forget trigger keywords in description
- Put all examples in SKILL.md (use examples.md)
- Try to do multiple things in one skill
- Grant more tools than needed
- Use generic names ("helper", "util")
- Forget `---` delimiters in frontmatter

## Description Writing Guide

The description is THE MOST IMPORTANT part for discovery.

**Formula**:
```
[Verb] + [what] + [context]. [Specifics]. Use when [trigger list], [patterns], [keywords].
```

**Good Examples**:
```yaml
description: Generate unit tests for Swift classes using XCTest. Creates test files with setup, teardown, methods. Use when you need to "write tests", "generate tests", working with .swift files, or setting up test coverage.
```

```yaml
description: Find unused variables in TypeScript files. Identifies dead code and suggests removal. Use when refactoring, checking for "unused variables", "dead code", or cleaning up .ts/.tsx files.
```

## Interactive Building

When user wants to create a skill:

```
🎯 Let's create a new skill!

1. What should it do?
   [Wait for answer]

2. When should it activate?
   [Wait for trigger keywords]

3. What tools needed?
   a) Read-only (analysis/review)
   b) Read + Write (generation)
   c) Full access (commands/builds)
   [Wait for choice]

4. What output format?
   [Wait for answer]

Creating your skill...
✅ Created at .claude/skills/[name]/SKILL.md
✅ Created examples.md

Test with: [suggested phrases]
```

## Common Patterns

### Pattern 1: Checker/Validator
```yaml
---
name: thing-checker
description: Check [what] for [issues]. Validates [aspects]. Use when [triggers].
allowed-tools: Read, Grep, Glob
---

## Process
1. Find files
2. Check against rules
3. Report violations
```

### Pattern 2: Generator
```yaml
---
name: thing-generator
description: Generate [what] from [source]. Creates [output]. Use when [triggers].
allowed-tools: Read, Write, Glob
---

## Process
1. Get requirements
2. Generate code
3. Write files
```

### Pattern 3: Analyzer
```yaml
---
name: thing-analyzer
description: Analyze [what] for [insights]. Provides [metrics]. Use when [triggers].
allowed-tools: Read, Grep, Glob, Bash
---

## Process
1. Collect data
2. Calculate metrics
3. Generate report
```

## Output After Creation

Provide:
1. ✅ Confirmation of files created
2. 📁 File paths
3. 🧪 Test phrases to verify
4. 📖 Brief usage guide
5. 🔄 Next steps (commit, test, share)

## Reference

**Templates**: See `templates.md` for 6 ready-to-use skill templates
**Examples**: See `examples.md` for 5 complete real-world skill examples

## Troubleshooting

**Skill not activating?**
- Make description more specific
- Add more trigger keywords
- Use file type mentions

**YAML errors?**
- Check `---` delimiters on own lines
- No tabs, use spaces only
- Quote description if it has colons

**Want different behavior?**
- Edit description for different triggers
- Adjust tool restrictions
- Update process steps

---

Ready to build! Tell me what skill you need.

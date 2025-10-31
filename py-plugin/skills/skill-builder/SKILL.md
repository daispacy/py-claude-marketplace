---
name: skill-builder
description: Create new Claude Code agent skills. Automatically analyzes requirements and generates complete skill with proper structure, triggers, and tools. Use when you want to "create a skill", "build a new skill", "make a skill for", or automate repetitive tasks.
allowed-tools: Read, Write, Glob, Bash
---

# Skill Builder

Autonomously create new Claude Code agent skills with intelligent analysis and generation.

## When to Activate

- "create a skill for...", "build a new skill"
- "make a skill that...", "I need a skill to..."
- "generate a skill for..."

## Autonomous Creation Process

### Step 1: Analyze User Request

**Automatically infer from the request:**

1. **Task Type Detection**:
   - Review/Check → Code Review Skill (Read, Grep, Glob)
   - Generate/Create → Code Generator (Read, Write, Glob)
   - Analyze/Report → Analyzer (Read, Grep, Glob, Bash)
   - Refactor/Improve → Refactoring Assistant (Read, Write, Grep, Glob)
   - Test → Test Assistant (Read, Write, Bash)
   - Document → Documentation Generator (Read, Write, Glob)

2. **Skill Name Derivation**:
   - Extract key technology/concept from request
   - Format: `[technology]-[action]` (e.g., "check iOS performance" → `ios-performance-check`)
   - Keep lowercase with hyphens, max 64 chars

3. **Trigger Keywords Extraction**:
   - Parse user's language for natural phrases
   - Add common variations and synonyms
   - Include file type mentions if applicable

4. **Tool Requirements**:
   - Read-only tasks → `Read, Grep, Glob`
   - Generation tasks → `Read, Write, Glob`
   - Command/build tasks → `Read, Write, Bash`
   - Complex workflows → No restrictions

5. **Output Format Selection**:
   - Review/Check → Report with issues and fixes
   - Generate → File creation confirmation with examples
   - Analyze → Metrics report with visualizations
   - Refactor → Proposal with before/after
   - Test → Test results and coverage report
   - Document → Generated documentation preview

### Step 2: Smart Question Strategy

**Only ask if truly ambiguous:**
- Multiple valid approaches? → Ask which approach
- Unclear scope? → Ask for scope clarification
- Critical choices? → Ask for user preference

**Never ask if inferable:**
- Skill name → Auto-generate from request
- Basic tools → Auto-select based on task type
- Common triggers → Auto-generate from context
- Output format → Auto-select based on skill type

### Step 3: Auto-Generate Skill Structure

**Automatically create complete skill with:**

#### Auto-Generated Skill Name
Format: `[technology]-[action]`
Examples:
- "check iOS naming" → `ios-naming-check`
- "generate React component" → `react-component-generator`
- "analyze dependencies" → `dependency-analyzer`

#### Auto-Generated Description
Template:
```
[Verb] [what] [context]. [Specifics]. Use when [trigger1], [trigger2], "[quoted phrases]", or [patterns].
```

Auto-include:
- Specific action extracted from request
- What it checks/generates/analyzes
- Trigger phrases derived from user's language
- File types if mentioned
- Natural language variations

#### Auto-Selected Tools
Based on detected task type:
- Review/Check → `Read, Grep, Glob`
- Generate → `Read, Write, Glob`
- Analyze with commands → `Read, Grep, Glob, Bash`
- Refactor → `Read, Write, Grep, Glob`
- Test with execution → `Read, Write, Bash`

#### Auto-Generated Content Structure

Select appropriate template based on task type (from templates.md):
- Code Review → Template 1
- Code Generator → Template 2
- Analyzer/Reporter → Template 3
- Refactoring Assistant → Template 4
- Test Assistant → Template 5
- Documentation Generator → Template 6

Populate template with:
- Auto-generated name, description, tools
- Task-specific process steps
- Relevant output format
- Examples from similar skills (from examples.md)

### Step 4: Generate and Validate

**Auto-create directory structure:**
```bash
mkdir -p .claude/skills/[auto-generated-name]
```

**Auto-generate files:**

1. **`SKILL.md`** (Required, Concise)
   - Frontmatter (name, description, allowed-tools)
   - When to Activate (trigger phrases)
   - Process steps (core workflow)
   - Output format (template structure)
   - Keep under 150 lines - core instructions only!

2. **`templates.md`** (Optional, for code/structure templates)
   - Code templates
   - File structure templates
   - Boilerplate examples
   - Use when skill generates code or files

3. **`examples.md`** (Optional, for detailed examples)
   - Real-world usage examples
   - Before/after code samples
   - Complex scenarios
   - Use when skill needs detailed guidance

4. **`standards.md`** (Optional, for rules/guidelines)
   - Coding standards
   - Naming conventions
   - Best practices
   - Reference documentation
   - Use when skill enforces specific rules

**Separation principle:**
- SKILL.md = Concise instructions (what to do, how to do it)
- Separate files = Supporting details (templates, examples, references)

**Auto-validate:**
- ✓ Valid YAML frontmatter with `---` delimiters
- ✓ Name lowercase with hyphens
- ✓ Description specific with quoted triggers
- ✓ Tools appropriate for task type
- ✓ Process steps clear and actionable
- ✓ SKILL.md concise (under 150 lines)
- ✓ Extra content moved to separate files

### Step 5: Present and Test

**Show user:**
```markdown
✅ Created skill: [name]

📁 Location: `.claude/skills/[name]/SKILL.md`

🎯 Try these phrases:
- "[trigger phrase 1]"
- "[trigger phrase 2]"
- "[trigger phrase 3]"

📖 Description: [generated description]
```

## Quick Reference: Task Types

| Type | Tools | Output | Example Name |
|------|-------|--------|--------------|
| Review | Read, Grep, Glob | Issues report | `security-review` |
| Generator | Read, Write, Glob | New files | `component-generator` |
| Analyzer | Read, Grep, Glob, Bash | Metrics report | `dependency-analyzer` |
| Refactor | Read, Write, Grep, Glob | Modified files | `extract-method` |
| Test | Read, Write, Bash | Test results | `test-runner` |
| Document | Read, Write, Glob | Documentation | `api-docs-generator` |

## Auto-Generation Examples

### Example 1: User says "create a skill to check TODO comments"
**Auto-analysis:**
- Task type: Review (check/find)
- Name: `todo-finder`
- Tools: `Read, Grep, Glob`
- Triggers: "find todos", "check todos", "show todos", "list fixmes"
- Output: Report organized by priority

**Action:** Auto-generate complete skill, create files, show confirmation

### Example 2: User says "I need to generate React components"
**Auto-analysis:**
- Task type: Generator (create/generate)
- Name: `react-component-generator`
- Tools: `Read, Write, Glob`
- Triggers: "create component", "generate component", "new component"
- Output: Component files with tests

**Action:** Auto-generate complete skill, create files, show confirmation

### Example 3: User says "make a skill for iOS performance issues"
**Auto-analysis:**
- Task type: Analyzer (check performance)
- Name: `ios-performance-check`
- Tools: `Read, Grep, Glob, Bash`
- Triggers: "check performance", "performance issues", "slow code"
- Output: Performance report with fixes

**Action:** Auto-generate complete skill, create files, show confirmation

## Standard Workflow

When user requests a skill:

1. **Analyze** request → Detect task type, extract key concepts
2. **Generate** skill name, description, triggers automatically
3. **Select** appropriate template and tools
4. **Create** `.claude/skills/[name]/SKILL.md` with complete content
5. **Validate** frontmatter, structure, triggers
6. **Present** summary with test phrases

**No questions asked unless truly ambiguous!**

## Creation Output Format

After auto-generating skill, show:

```markdown
✅ Skill Created: [name]

📁 Files created:
  - `.claude/skills/[name]/SKILL.md` (core instructions)
  - `.claude/skills/[name]/templates.md` (if applicable)
  - `.claude/skills/[name]/examples.md` (if applicable)
  - `.claude/skills/[name]/standards.md` (if applicable)

🔧 Type: [task-type]
🛠️  Tools: [tool-list]
📄 Lines: [line-count] (SKILL.md is concise!)

🎯 Test with these phrases:
- "[natural trigger 1]"
- "[natural trigger 2]"
- "[natural trigger 3]"

📖 Full description:
[Generated description with all triggers]

✅ Ready to use! Try one of the test phrases above.
```

## Internal References

Use these for generation (don't show to user):
- **templates.md**: 6 skill templates for different task types
- **examples.md**: 5 complete real-world examples

## Key Principles

1. **Be autonomous**: Infer everything possible from the user's request
2. **Ask minimally**: Only ask if genuinely ambiguous (approach, scope, critical choices)
3. **Generate completely**: Create full SKILL.md with all sections
4. **Validate automatically**: Check frontmatter, structure, triggers before presenting
5. **Present clearly**: Show what was created and how to test it

## Important Rules

### Auto-Generation
- **Auto-generate** skill name from request (lowercase-with-hyphens)
- **Auto-detect** task type to select template and tools
- **Auto-extract** trigger phrases from user's language
- **Auto-create** description with specific triggers in quotes
- **Auto-select** appropriate tools based on task type

### Quality Standards
- **No generic names**: Always use specific technology/action names
- **No vague descriptions**: Always include specific triggers and file types
- **Valid YAML**: Always use `---` delimiters and proper frontmatter format

### File Organization
- **SKILL.md must be concise**: Under 150 lines, core instructions only
- **Separate templates**: Move code templates to `templates.md`
- **Separate examples**: Move detailed examples to `examples.md`
- **Separate standards**: Move rules/guidelines to `standards.md`
- **Clear separation**: Instructions in SKILL.md, details in other files

---

**Ready for autonomous skill generation!** Just tell me what skill you need.

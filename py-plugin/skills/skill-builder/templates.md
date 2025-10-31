# Skill Templates

Quick-start templates for common skill types.

## Template 1: Code Review Skill

```yaml
---
name: [technology]-review
description: Review [technology] code for [standards/patterns]. Checks [list of things]. Use when reviewing [file types], checking [patterns], or mentions "[keywords]".
allowed-tools: Read, Grep, Glob
---

# [Technology] Code Review

Review [technology] code against project standards.

## When to Activate

- "review [technology]"
- "check [file type]"
- "[specific patterns]"

## Review Checklist

### Category 1
- [ ] Check item 1
- [ ] Check item 2

### Category 2
- [ ] Check item 1
- [ ] Check item 2

## Common Issues

### ❌ Anti-Pattern 1
**Problem**:
```
// bad code
```

**Solution**:
```
// good code
```

### ❌ Anti-Pattern 2
[Pattern description]

## Output Format

```markdown
# [Technology] Review Report

## Summary
- Issues found: X
- By severity: Critical: X, High: X, Medium: X, Low: X

## Issues

### [Category] - [Issue Title]
**File**: `path/to/file:line`
**Severity**: [Level]

**Current**:
```
// current code
```

**Fix**:
```
// fixed code
```

**Why**: [Explanation]
```

## Reference

Standards: [Link to standards doc]
```

---

## Template 2: Code Generator

```yaml
---
name: [thing]-generator
description: Generate [what] for [purpose]. Creates [file types] with [features]. Use when you need to "generate [thing]", "create [thing]", or "scaffold [thing]".
allowed-tools: Read, Write, Glob
---

# [Thing] Generator

Generate [description] following project patterns.

## When to Activate

- "generate [thing]"
- "create [thing]"
- "scaffold [thing]"
- "new [thing]"

## Generation Process

### Step 1: Gather Requirements

Ask user:
- Name of [thing]
- Location/path
- Options/variants
- Additional features

### Step 2: Validate Input

Check:
- Name format valid
- Path exists
- No conflicts with existing files

### Step 3: Generate Files

Create:
```
output-directory/
├── [file1].ext
├── [file2].ext
└── tests/
    └── [file1]Tests.ext
```

### Step 4: Confirm Creation

Show:
- Files created
- Next steps
- Usage examples

## File Templates

### Template: [File Type 1]
```[language]
// Template content here
class [Name] {
    // Generated code
}
```

### Template: [File Type 2]
```[language]
// Template content here
```

## Output Format

```markdown
# Generation Complete ✅

## Files Created
- `path/to/file1.ext` - [Description]
- `path/to/file2.ext` - [Description]
- `path/to/tests/file1Tests.ext` - [Description]

## Next Steps
1. [Action 1]
2. [Action 2]
3. [Action 3]

## Usage Example
```[language]
// How to use the generated code
```
```

## Customization

Edit these files to customize:
- [File 1]: [What to change]
- [File 2]: [What to change]
```

---

## Template 3: Analyzer/Reporter

```yaml
---
name: [thing]-analyzer
description: Analyze [what] and report [insights]. Provides metrics on [aspects]. Use when you need to "analyze [thing]", "check [metrics]", or investigate [problems].
allowed-tools: Read, Grep, Glob, Bash
---

# [Thing] Analyzer

Analyze [description] and provide actionable insights.

## When to Activate

- "analyze [thing]"
- "report on [thing]"
- "check [metrics]"
- "[problem investigation]"

## Analysis Process

### Step 1: Scan Codebase

Find:
- [Pattern 1]
- [Pattern 2]
- [Pattern 3]

### Step 2: Collect Metrics

Calculate:
- Metric 1: [Description]
- Metric 2: [Description]
- Metric 3: [Description]

### Step 3: Identify Issues

Flag:
- Issue type 1
- Issue type 2
- Issue type 3

### Step 4: Generate Report

Provide:
- Summary with key metrics
- Detailed findings by category
- Recommendations
- Trend analysis (if applicable)

## Metrics

### Metric 1: [Name]
**What**: [Description]
**Why**: [Importance]
**Good range**: [Values]
**Warning**: [Threshold]
**Critical**: [Threshold]

### Metric 2: [Name]
[Same structure]

## Output Format

```markdown
# [Thing] Analysis Report

## Executive Summary
- Total [items]: X
- Health score: X/100
- Issues found: X
- Recommendations: X

## Key Metrics

| Metric | Value | Status | Trend |
|--------|-------|--------|-------|
| [Metric 1] | X | ✅ Good | ↑ |
| [Metric 2] | Y | ⚠️ Warning | → |
| [Metric 3] | Z | 🔴 Critical | ↓ |

## Detailed Findings

### [Category 1]
**Status**: [Good/Warning/Critical]
**Details**: [Description]

**Issues**:
1. [Issue 1] - File: `path:line`
2. [Issue 2] - File: `path:line`

### [Category 2]
[Same structure]

## Recommendations

### Priority 1 (Critical)
1. [Action] - Impact: [High/Medium/Low]
   - Why: [Reason]
   - How: [Steps]

### Priority 2 (High)
[Same structure]

### Priority 3 (Medium)
[Same structure]

## Trends

[If analyzing over time]
- [Metric 1]: [Trend description]
- [Metric 2]: [Trend description]

## Next Steps
1. [Action 1]
2. [Action 2]
3. [Action 3]
```

---

## Template 4: Refactoring Assistant

```yaml
---
name: [refactoring]-helper
description: Help [refactor what] by [method]. Identifies [code smells] and suggests [improvements]. Use when need to "refactor [thing]", code smells, or mentions "[specific refactoring]".
allowed-tools: Read, Write, Grep, Glob
---

# [Refactoring] Helper

Assist with [refactoring type] following best practices.

## When to Activate

- "refactor [thing]"
- "[specific refactoring name]"
- "improve [code aspect]"
- "code smell: [smell]"

## Refactoring Process

### Step 1: Identify Candidates

Find code that:
- [Criteria 1]
- [Criteria 2]
- [Criteria 3]

### Step 2: Analyze Impact

Check:
- Dependencies
- Test coverage
- Breaking changes
- Scope of change

### Step 3: Propose Refactoring

Show:
- Current structure
- Proposed structure
- Benefits
- Risks

### Step 4: Execute (if approved)

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. Verify tests pass

## Common Refactorings

### Refactoring 1: [Name]
**When**: [Conditions]
**Why**: [Benefits]

**Before**:
```[language]
// Original code
```

**After**:
```[language]
// Refactored code
```

**Steps**:
1. [Step 1]
2. [Step 2]

### Refactoring 2: [Name]
[Same structure]

## Output Format

```markdown
# Refactoring Proposal

## Overview
**Type**: [Refactoring name]
**Scope**: [Files affected]
**Estimated effort**: [Time]
**Risk level**: [Low/Medium/High]

## Current State

**Problems**:
- [Problem 1]
- [Problem 2]

**Code**:
```[language]
// Current implementation
```

## Proposed Changes

**Benefits**:
- [Benefit 1]
- [Benefit 2]

**New structure**:
```[language]
// Refactored implementation
```

## Migration Plan

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Testing Strategy
- [Test approach 1]
- [Test approach 2]

## Risks & Mitigation
- Risk: [Risk 1]
  - Mitigation: [How to handle]

## Approval Required
Proceed with refactoring? (Y/N)
```

---

## Template 5: Test Assistant

```yaml
---
name: [testing]-helper
description: Help with [test type] for [technology]. Generates test cases, identifies coverage gaps, runs tests. Use when need to "write tests", "generate tests", "run tests", or check test coverage.
allowed-tools: Read, Write, Grep, Glob, Bash
---

# [Testing] Helper

Assist with [test type] for better code quality.

## When to Activate

- "write tests"
- "generate tests"
- "run tests"
- "test coverage"
- "check tests"

## Testing Process

### Step 1: Analyze Code

Identify:
- Functions/methods to test
- Edge cases
- Error scenarios
- Integration points

### Step 2: Generate Test Cases

Create tests for:
- Happy path
- Error cases
- Edge cases
- Integration scenarios

### Step 3: Check Coverage

Report:
- Lines covered
- Branches covered
- Functions covered
- Missing coverage

### Step 4: Run Tests

Execute:
- Unit tests
- Integration tests
- Report results

## Test Template

```[language]
// Test template for [language/framework]

class [ClassName]Tests {
    // Setup
    func setUp() {
        // Initialize test dependencies
    }

    // Teardown
    func tearDown() {
        // Clean up
    }

    // Test: [Scenario] - [Expected Result]
    func test[Method]_[Scenario]_[Expected]() {
        // Given
        [Setup]

        // When
        [Action]

        // Then
        [Assertions]
    }
}
```

## Output Format

```markdown
# Test Generation Report

## Summary
- Tests generated: X
- Coverage: X%
- Scenarios covered: X

## Generated Tests

### [ClassName]Tests

#### Test 1: [Method] - [Scenario]
```[language]
func test[Method]_[Scenario]_[Expected]() {
    // Test code
}
```

**Covers**: [What this tests]
**Assertions**: X

#### Test 2: [Method] - [Scenario]
[Same structure]

## Coverage Report

| File | Coverage | Status |
|------|----------|--------|
| [File1] | 85% | ✅ Good |
| [File2] | 45% | ⚠️ Low |

## Missing Coverage

### [File]: [Method]
**Not covered**:
- [Scenario 1]
- [Scenario 2]

**Suggested tests**:
```[language]
// Suggested test code
```

## Next Steps
1. Review generated tests
2. Add edge case tests for [areas]
3. Run full test suite
4. Aim for 80%+ coverage
```

---

## Template 6: Documentation Generator

```yaml
---
name: [doc-type]-generator
description: Generate [documentation type] from [source]. Creates [format] docs with [features]. Use when need to "document [thing]", "generate docs", or "create [doc type]".
allowed-tools: Read, Write, Glob
---

# [Doc Type] Generator

Generate [documentation description] from code.

## When to Activate

- "document [thing]"
- "generate docs"
- "create documentation"
- "[specific doc type]"

## Generation Process

### Step 1: Extract Information

Parse:
- [Element 1]
- [Element 2]
- [Element 3]

### Step 2: Format Documentation

Create:
- Overview
- Details
- Examples
- References

### Step 3: Write Files

Output:
```
docs/
├── README.md
├── api/
│   └── [module].md
└── guides/
    └── [topic].md
```

## Documentation Template

```markdown
# [Title]

## Overview
[Brief description]

## [Section 1]
[Content]

### [Subsection]
[Details]

## Examples

### Example 1: [Scenario]
```[language]
// Example code
```

**Description**: [What it does]

## API Reference

### [Class/Function Name]
**Description**: [What it does]

**Parameters**:
- `param1` ([type]): [Description]
- `param2` ([type]): [Description]

**Returns**: [Return type and description]

**Example**:
```[language]
// Usage example
```

## See Also
- [Related doc 1]
- [Related doc 2]
```

## Output Format

```markdown
# Documentation Generated ✅

## Files Created
- `docs/README.md` - Main overview
- `docs/api/[module].md` - API reference
- `docs/guides/[topic].md` - User guide

## Content Summary
- Modules documented: X
- Functions documented: X
- Examples included: X

## Preview

[Show sample of generated documentation]

## Next Steps
1. Review generated docs
2. Add examples where needed
3. Update links
4. Commit to repository
```

---

## Usage

1. Choose a template that fits your need
2. Replace all `[placeholders]` with specifics
3. Customize sections for your use case
4. Add project-specific examples
5. Save as `.claude/skills/[skill-name]/SKILL.md`
6. Test with suggested trigger phrases

## Tips

- Start with a template closest to your need
- Keep descriptions very specific
- Add lots of examples
- Show output format clearly
- Test thoroughly before sharing

# Templates

## Code Review Report Template

Use this structure for review mode output:

```markdown
# 📝 Code Review Analysis

## Summary
[High-level overview of the changes - what was modified and overall assessment]

## Critical Issues ⛔
[Problems that MUST be fixed before merge - blocking issues]
- Issue 1: Description
  - Location: file.swift:line
  - Impact: Why this is critical
  - Fix: Suggested solution

## Major Issues ⚠️
[Important problems that SHOULD be addressed]
- Issue 1: Description
  - Location: file.swift:line
  - Impact: Potential problems
  - Fix: Suggested solution

## Minor Issues 💡
[Nice-to-have improvements and suggestions]
- Issue 1: Description
  - Location: file.swift:line
  - Suggestion: How to improve

## Positive Observations ✅
[What was done well in this implementation]
- Good practice 1
- Good practice 2

## Recommendations 📚
[Suggestions for improvement and best practices]
- Recommendation 1
- Recommendation 2

## Security Review 🔒
[Security considerations and potential vulnerabilities]
- Security aspect 1
- Security aspect 2

## Testing Assessment 🧪
[Evaluation of test coverage and quality]
- Test coverage assessment
- Missing test scenarios
- Test quality feedback

## Performance Analysis ⚡
[Potential performance impacts and optimizations]
- Performance consideration 1
- Performance consideration 2

# 🔍 Review Decision

**Status**: [Approved ✅ / Changes Requested ⚠️]

**Approval Criteria Met:**
- [ ] No critical issues
- [ ] Major issues addressed or acceptable
- [ ] Code follows iOS best practices
- [ ] Adequate test coverage
- [ ] No security vulnerabilities

**Next Steps:**
[Action items or recommendations]
```

## Review Summary Template

Use this for final review summary:

```markdown
# 📝 Code Review Findings

## Critical Issues
<List of critical issues that must be fixed before merge>

## Major Issues
<List of major issues that should be addressed>

## Minor Issues
<List of minor improvements and suggestions>

## Positive Observations
<What was done well in this implementation>

# 🔍 Review Decision

**Status**: [Approved ✅ / Changes Requested ⚠️]

**Next Steps**:
<List of action items or recommendations>
```

## MR Description Template (Update Mode)

Use this structure for creating/updating merge request descriptions:

```markdown
# 📲 What

Close #{issue_number}

[Clear description of what changes were made and why]
[Explain the business context and user impact]

# 🛠 How

[Technical details of the implementation approach]
[Key architectural decisions and rationale]
[Notable patterns or techniques used]
[Any important implementation details]

# 📚 How to Use

**Note**: Only include this section for new features or streamlined features. Omit for bug fixes.

\`\`\`swift
// Example usage showing how to integrate the new feature
// Clear, practical code examples

// Example 1: Basic usage
let example = NewFeature()
example.configure()

// Example 2: Advanced usage
let advanced = NewFeature.Builder()
    .withOption(.custom)
    .build()
\`\`\`

/assign me
/label ~"product::payoomerchant" ~"team::ios" ~"In Review"
```

## MR Description Template (No Issue)

When no issue number is provided:

```markdown
# 📲 What

[Clear description of the purpose and goals of these changes]
[Explain what problem is being solved]

# 🛠 How

[Technical implementation details]
[Architectural decisions]
[Patterns and techniques used]

# 📚 How to Use

[Only for new features - include usage examples]

/assign me
/label ~"product::payoomerchant" ~"team::ios" ~"In Review"
```

## Issue Categorization Guidelines

### Critical Issues ⛔
- Memory leaks or retain cycles
- Crashes or fatal errors
- Security vulnerabilities
- Data loss or corruption
- Breaking API changes without migration
- Violates Clean Architecture layer boundaries

### Major Issues ⚠️
- Incorrect business logic
- Poor error handling
- Missing session error handling (`.catchSessionError`)
- Missing dispose bags for RxSwift
- Naming convention violations
- Missing or insufficient tests
- Performance bottlenecks

### Minor Issues 💡
- Code style inconsistencies
- Missing documentation
- Overly complex code that could be simplified
- Opportunities for code reuse
- Suggestions for better patterns
- Minor refactoring opportunities

## Code Review Guidelines Reference

Always follow the guidelines in:
`.github/instructions/ios-merchant-code-review.instructions.md`

Key areas to review:
1. Clean Architecture compliance
2. MVVM with RxSwift patterns
3. Memory management (retain cycles, dispose bags)
4. Session error handling
5. Naming conventions
6. Layer separation
7. Dependency injection usage
8. Test coverage

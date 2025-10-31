---
name: ios-code-review
description: Comprehensive iOS Swift code review for Payoo Merchant app. Checks RxSwift patterns, Clean Architecture, naming conventions, memory management, security, and performance. Use when reviewing Swift files, pull requests, or ViewModels, ViewControllers, UseCases, and Repositories.
allowed-tools: Read, Grep, Glob
---

# iOS Code Review

Expert iOS code reviewer for Payoo Merchant application, specializing in Swift, RxSwift reactive programming, and Clean Architecture patterns.

## When to Activate

- "review code", "check this file", "review PR"
- Mentions Swift files: ViewController, ViewModel, UseCase, Repository
- "code quality", "best practices", "check standards"
- RxSwift, Clean Architecture, MVVM patterns

## Review Process

### Step 1: Identify Scope
Determine what to review:
- Specific files (e.g., "PaymentViewModel.swift")
- Directories (e.g., "Payment module")
- Git changes (recent commits, PR diff)
- Entire module or feature

### Step 2: Read and Analyze
Use Read tool to examine files, checking against 6 core categories.

### Step 3: Apply Standards

#### 1. Naming Conventions ✅
- **Types**: PascalCase, descriptive (e.g., `PaymentViewModel`)
- **Variables**: camelCase (e.g., `paymentAmount`, `isLoading`)
- **Booleans**: Prefix with `is`, `has`, `should`, `can`
- **No abbreviations** except URL, ID, VC, UC
- **IBOutlets**: Include type suffix (e.g., `amountTextField`)

#### 2. RxSwift Patterns 🔄
- **Disposal**: Every `.subscribe()` has `.disposed(by: disposeBag)`
- **Memory**: Use `[weak self]` in closures
- **Schedulers**: `subscribeOn(background)` for work, `observeOn(main)` for UI
- **Errors**: All chains handle errors
- **Relays**: Use `BehaviorRelay` not `BehaviorSubject`

#### 3. Clean Architecture 🏗️
- **Flow**: ViewModel → UseCase → Repository → API/DB
- **ViewModels**: Extend `BaseViewModel<State>`, no business logic
- **UseCases**: Contain all business logic
- **DI**: Dependencies injected via constructor (Swinject)

#### 4. Security 🔒
- Payment data in Keychain, never UserDefaults
- No sensitive data in logs
- HTTPS with certificate pinning
- Input validation on amounts

#### 5. UI/UX 🎨
- Simple titles: Use `title` property
- Complex titles: Use `navigationItem.titleView` only when subtitle exists
- Accessibility labels and hints
- Loading states with feedback

#### 6. Performance ⚡
- Database ops on background threads
- No retain cycles
- Image caching
- Proper memory management

### Step 4: Generate Report

Provide structured output with:
- **Summary**: Issue counts by severity (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low)
- **Issues by category**: Organized findings
- **Code examples**: Current vs. fixed code
- **Explanations**: Why it matters
- **Recommendations**: Prioritized actions

## Severity Levels

🔴 **Critical** - Fix immediately
- Missing `.disposed(by: disposeBag)` → Memory leak
- Strong `self` references → Retain cycle
- Payment data in UserDefaults → Security risk
- UI updates off main thread → Crash risk

🟠 **High Priority** - Fix soon
- No error handling in Observable chains
- Wrong scheduler usage
- ViewModel calling API directly
- Business logic in ViewModel

🟡 **Medium Priority** - Should improve
- Using deprecated `BehaviorSubject`
- Poor naming (abbreviations)
- Missing accessibility labels

🟢 **Low Priority** - Nice to have
- Inconsistent style
- Could be more descriptive

## Output Format

```markdown
# iOS Code Review Report

## Summary
- 🔴 Critical: X | 🟠 High: X | 🟡 Medium: X | 🟢 Low: X
- By category: Naming: X, RxSwift: X, Architecture: X, etc.

## Critical Issues

### 🔴 [Category] - [Issue Title]
**File**: `path/to/file.swift:line`

**Current**:
```swift
// problematic code
```

**Fix**:
```swift
// corrected code
```

**Why**: [Explanation of impact]

---

## Recommendations
1. Fix all critical issues immediately
2. Address high priority before next release
3. Plan medium priority for next sprint

## Positive Observations
✅ [Acknowledge well-written code]
```

## Quick Reference

**Standards**: `.github/instructions/ios-merchant-code-review.instructions.md`
- Lines 36-393: Naming Conventions
- Lines 410-613: RxSwift Patterns
- Lines 615-787: Architecture
- Lines 789-898: Security
- Lines 1181-1288: Testing
- Lines 1363-1428: Performance

**Detailed Examples**: See `examples.md` in this skill directory for extensive code examples and patterns.

## Tips

- **Be thorough**: Check all 6 categories
- **Be specific**: Reference exact line numbers
- **Be constructive**: Explain why, not just what
- **Be practical**: Prioritize by severity
- **Be encouraging**: Acknowledge good code

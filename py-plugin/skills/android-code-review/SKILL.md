---
name: android-code-review
description: Comprehensive Android Kotlin code review for Payoo Android app. Checks Kotlin best practices, coroutines, Clean Architecture, MVVM patterns, lifecycle management, dependency injection, memory management, security, and performance. Use when reviewing Kotlin files, pull requests, or ViewModels, Activities, Fragments, UseCases, and Repositories.
allowed-tools: Read, Grep, Glob
---

# Android Code Review

Expert Android code reviewer for Payoo Android application, specializing in Kotlin, Coroutines, Jetpack components, and Clean Architecture patterns.

## When to Activate

- "review android code", "check android file", "review android PR"
- Mentions Kotlin/Java files: Activity, Fragment, ViewModel, UseCase, Repository
- "code quality", "best practices", "check android standards"
- Coroutines, Clean Architecture, MVVM patterns, Jetpack components

## Review Process

### Step 1: Identify Scope
Determine what to review:
- Specific files (e.g., "PaymentViewModel.kt")
- Directories (e.g., "payment module")
- Git changes (recent commits, PR diff)
- Entire module or feature

### Step 2: Read and Analyze
Use Read tool to examine files, checking against 7 core categories.

### Step 3: Apply Standards

#### 1. Naming Conventions ✅
- **Types**: PascalCase, descriptive (e.g., `PaymentViewModel`)
- **Variables**: camelCase (e.g., `paymentAmount`, `isLoading`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)
- **Booleans**: Prefix with `is`, `has`, `should`, `can`
- **No abbreviations** except URL, ID, API, HTTP, UI
- **Views**: Include type suffix (e.g., `amountEditText`, `submitButton`)

#### 2. Kotlin Best Practices 🎯
- **Null Safety**: Use `?` and `!!` appropriately, prefer safe calls
- **Data Classes**: Use for DTOs and models
- **Sealed Classes**: For state management and result types
- **Extension Functions**: For reusable utilities
- **Scope Functions**: Use `let`, `apply`, `run`, `also`, `with` correctly
- **Immutability**: Prefer `val` over `var`

#### 3. Coroutines Patterns 🔄
- **Scope**: Use `viewModelScope`, `lifecycleScope` appropriately
- **Dispatchers**: `Dispatchers.IO` for network/DB, `Dispatchers.Main` for UI
- **Cancellation**: All coroutines properly cancelled
- **Error Handling**: Use `try-catch` or `runCatching` in coroutines
- **Flows**: Use `StateFlow`, `SharedFlow` for reactive data
- **No blocking**: Never use `runBlocking` in production code

#### 4. Clean Architecture 🏗️
- **Flow**: ViewModel → UseCase → Repository → DataSource (API/DB)
- **ViewModels**: Extend `ViewModel`, expose UI state via `StateFlow`
- **UseCases**: Contain business logic, single responsibility
- **Repositories**: Abstract data sources
- **DI**: Dependencies injected (Dagger/Hilt/Koin)
- **Layers**: Strict separation (Presentation/Domain/Data)

#### 5. Lifecycle Management 🔁
- **ViewModels**: Don't hold Activity/Fragment references
- **Observers**: Use `viewLifecycleOwner` in Fragments
- **Coroutines**: Launch in lifecycle-aware scopes
- **Resources**: Clean up in `onDestroy` or `onCleared`
- **Configuration Changes**: Handle properly

#### 6. Security 🔒
- **Sensitive Data**: Use EncryptedSharedPreferences
- **API Keys**: Never hardcode, use BuildConfig
- **Network**: HTTPS only, certificate pinning if needed
- **Logs**: No sensitive data in production logs
- **Input Validation**: Sanitize user inputs
- **ProGuard/R8**: Proper obfuscation rules

#### 7. Performance ⚡
- **Background Work**: Network and DB on IO dispatcher
- **Memory Leaks**: No Activity/Context leaks
- **RecyclerView**: Use DiffUtil, ViewBinding
- **Images**: Use Coil/Glide with proper caching
- **Database**: Room queries optimized with indexes
- **Lazy Loading**: Load data on demand

### Step 4: Generate Report

Provide structured output with:
- **Summary**: Issue counts by severity (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low)
- **Issues by category**: Organized findings
- **Code examples**: Current vs. fixed code
- **Explanations**: Why it matters
- **Recommendations**: Prioritized actions

## Severity Levels

🔴 **Critical** - Fix immediately
- Memory leaks (Activity/Context references)
- Coroutines not cancelled → Resource leak
- Sensitive data in plain SharedPreferences
- UI updates on background thread → Crash risk
- Hardcoded API keys or secrets

🟠 **High Priority** - Fix soon
- Missing error handling in coroutines
- Wrong Dispatcher usage
- ViewModel calling repository directly (skip UseCase)
- Business logic in ViewModel/Activity
- No ProGuard rules for critical code

🟡 **Medium Priority** - Should improve
- Not using lifecycle-aware components
- Poor naming conventions
- Not using data classes for models
- Missing null safety checks
- Inefficient RecyclerView usage

🟢 **Low Priority** - Nice to have
- Inconsistent code style
- Could use more extension functions
- Documentation improvements

## Output Format

```markdown
# Android Code Review Report

## Summary
- 🔴 Critical: X | 🟠 High: X | 🟡 Medium: X | 🟢 Low: X
- By category: Naming: X, Kotlin: X, Coroutines: X, Architecture: X, etc.

## Critical Issues

### 🔴 [Category] - [Issue Title]
**File**: `path/to/file.kt:line`

**Current**:
```kotlin
// problematic code
```

**Fix**:
```kotlin
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

**Standards**: See `standards.md` in this skill directory for detailed Android coding standards including:
- Kotlin best practices and idioms
- Coroutines patterns and anti-patterns
- Clean Architecture implementation
- Dependency injection patterns
- Security guidelines
- Performance optimization techniques

**Examples**: See `examples.md` for extensive code examples, common issues, and recommended patterns.

## Tips

- **Be thorough**: Check all 7 categories
- **Be specific**: Reference exact line numbers
- **Be constructive**: Explain why, not just what
- **Be practical**: Prioritize by severity
- **Be encouraging**: Acknowledge good code
- **Context matters**: Consider app-specific requirements

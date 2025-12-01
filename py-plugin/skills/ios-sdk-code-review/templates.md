# Review Output Templates

## Standard Code Review Report Template

```markdown
## Code Review: {FileName}

### ✅ Strengths
- Follows MVVM pattern with proper protocol definitions
- Clean dependency injection via constructor
- Proper memory management with weak delegates
- Good separation of concerns

### ⚠️ Issues Found

#### 🔴 Critical Issues

**Issue #1: Memory Leak - Strong Delegate Reference**
**Location:** `DepositViewModel.swift:15`
**Impact:** Creates retain cycle between ViewModel and ViewController, causing memory leak
**Fix:**
\```swift
// Current code (line 15)
var delegate: DepositViewModelDelegate?

// Suggested fix
weak var delegate: DepositViewModelDelegate?
\```

**Issue #2: Business Logic in ViewController**
**Location:** `DepositViewController.swift:89-95`
**Impact:** Violates MVVM pattern, makes testing difficult, breaks separation of concerns
**Fix:**
\```swift
// Current code (in ViewController)
func validateAmount(_ amount: Double) -> Bool {
    return amount >= minAmount && amount <= maxAmount
}

// Suggested fix: Move to ViewModel or UseCase
// In DepositViewModel:
func validate(amount: Double) -> Bool {
    return depositAmountUC.validate(amount)
}
\```

#### 🟡 Warnings

**Warning #1: Missing weak self in closure**
**Location:** `DepositViewModel.swift:67`
**Suggestion:**
\```swift
// Current
service.fetch { data in
    self.handleData(data)
}

// Better
service.fetch { [weak self] data in
    self?.handleData(data)
}
\```

**Warning #2: Force unwrapping**
**Location:** `BankAccountCell.swift:42`
**Suggestion:** Use optional binding instead of force unwrap
\```swift
// Current
let bank = bankDict[code]!

// Better
guard let bank = bankDict[code] else { return }
\```

#### 🔵 Suggestions

**Enhancement #1: Extract magic numbers to constants**
**Location:** `DepositViewController.swift:134, 156`
**Benefit:** Improves maintainability and readability
\```swift
// Add to top of class
private enum Layout {
    static let spacing: CGFloat = 14
    static let itemsPerRow = 3
}
\```

**Enhancement #2: Add documentation for public API**
**Location:** `PayooEwallet.swift:25-30`
**Benefit:** Better API discoverability for SDK consumers

### 📊 Summary
- Critical Issues: 2
- Warnings: 2
- Suggestions: 2
- Overall: **Needs Work** (Critical issues must be fixed)

### 🎯 Priority Actions
1. Fix memory leak by marking delegate as weak (Critical)
2. Move business logic from ViewController to ViewModel/UseCase (Critical)
3. Add [weak self] to closure captures (Warning)
4. Replace force unwraps with safe optional handling (Warning)
```

## Quick Review Template (Minor Issues)

```markdown
## Quick Review: {FileName}

### ✅ Overall: Pass

Code follows project standards with minor improvements suggested.

### Suggestions:
1. **Line 45**: Consider extracting magic number to constant
2. **Line 78**: Add documentation comment for public method
3. **Line 102**: Use `guard let` instead of `if let` for early return

No critical issues found. Code is ready to merge.
```

## Architecture Review Template

```markdown
## Architecture Review: {Feature}

### Layer Analysis

#### ✅ Presentation Layer
- ViewModel follows protocol pattern
- Delegate properly defined
- No UIKit in ViewModel
- Clean separation

#### ✅ Domain Layer
- UseCase has single responsibility
- No framework dependencies
- Proper error handling
- Good abstraction

#### ⚠️ Data Layer
**Issue**: DataSource directly accessed from ViewController
**Suggestion**: Inject via ViewModel for better testability

### Dependency Flow
\```
ViewController → ViewModel → UseCase → Service
     ✓              ✓          ✓         ✓
\```

### Recommendations
1. Consider extracting validation logic to separate UseCase
2. Add unit tests for ViewModel
3. Document public API methods
```

## Memory Review Template

```markdown
## Memory Safety Review: {FileName}

### Analysis

#### Delegate References
- ✅ Line 23: `weak var delegate` - Correct
- ❌ Line 45: `var delegate` - Should be weak

#### Closure Captures
- ✅ Line 67: Uses `[weak self]` - Correct
- ❌ Line 89: Strong self capture - Add `[weak self]`
- ✅ Line 102: Uses `[weak self]` - Correct

#### Resource Cleanup
- ⚠️ Missing `deinit` - Add cleanup for timer/observers

### Fixes Required

**Fix delegate reference:**
\```swift
weak var delegate: SomeDelegate?
\```

**Fix closure capture:**
\```swift
service.fetch { [weak self] data in
    guard let self = self else { return }
    self.handleData(data)
}
\```

**Add cleanup:**
\```swift
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
\```
```

## API Design Review Template

```markdown
## API Design Review: {ClassName}

### Public Interface

#### Method Signatures
- ✅ Clear, descriptive names
- ✅ Proper use of completion handlers
- ⚠️ Missing documentation comments

#### Error Handling
- ✅ Typed errors
- ✅ LocalizedError conformance
- ✅ Recovery suggestions

#### Thread Safety
- ⚠️ Completion handlers not guaranteed on main thread
- Suggestion: Document threading behavior

### Recommendations

**Add documentation:**
\```swift
/// Deposits the specified amount to the user's e-wallet.
///
/// - Parameters:
///   - amount: Amount in VND to deposit
///   - completion: Called on main thread when complete
/// - Note: User must be authenticated and KYC verified
public func deposit(
    amount: Double,
    completion: @escaping (Result<DepositResult, DepositError>) -> Void
)
\```

**Ensure main thread callbacks:**
\```swift
DispatchQueue.main.async {
    completion(.success(result))
}
\```
```

## UseCase Review Template

```markdown
## UseCase Review: {UseCaseName}

### Single Responsibility Check
- ✅ Focused on single business capability
- ✅ Clear, specific purpose

### Dependencies
- ✅ Properly injected via constructor
- ✅ Uses protocols, not concrete types
- ✅ No service locator pattern

### Error Handling
- ✅ Typed errors defined
- ✅ Localized error messages
- ✅ Proper error propagation

### Testability
- ✅ No external dependencies
- ✅ Pure business logic
- ✅ Easy to mock dependencies

### Recommendations
None - UseCase follows best practices.
```

## ViewModel Review Checklist Template

```markdown
## ViewModel Checklist: {ViewModelName}

### Protocol Design
- [ ] Has `{Name}ViewModelType` protocol
- [ ] Has `{Name}ViewModelDelegate` protocol
- [ ] Delegate marked `weak`
- [ ] Clear separation of concerns

### Dependencies
- [ ] All dependencies injected via `init`
- [ ] Uses UseCases for business logic
- [ ] No direct service access
- [ ] Context pattern used appropriately

### Memory Management
- [ ] Weak delegate reference
- [ ] `[weak self]` in closures
- [ ] Proper cleanup in `deinit` (if needed)
- [ ] No retain cycles

### Testability
- [ ] No UIKit imports
- [ ] Protocol-based design
- [ ] Mockable dependencies
- [ ] Pure presentation logic

### Results
- **Passed**: X/Y checks
- **Issues**: See details below
```

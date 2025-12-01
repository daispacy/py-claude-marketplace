# iOS SDK Code Standards

Project-specific standards and guidelines for Payoo iOS Frameworks.

## Architecture Standards

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│   Presentation Layer (Scenes)          │
│   - ViewControllers                     │
│   - ViewModels                          │
│   - Views, Cells                        │
└──────────────┬──────────────────────────┘
               │ depends on
               ▼
┌─────────────────────────────────────────┐
│   Domain Layer (UseCase)                │
│   - UseCases (Business Logic)           │
│   - Domain Models                       │
│   - Protocols                           │
└──────────────┬──────────────────────────┘
               │ depends on
               ▼
┌─────────────────────────────────────────┐
│   Data Layer                            │
│   - DataSources                         │
│   - Services (API)                      │
│   - Repositories                        │
└─────────────────────────────────────────┘
```

**Rules:**
1. Dependencies only point **downward** (Presentation → Domain → Data)
2. Domain layer has **no dependencies** on Presentation or Data
3. ViewModels **never** directly access Services (must use UseCases)
4. No UIKit in Domain or Data layers

### MVVM Standards

**Protocol Definition Required:**

Every ViewModel must have:
1. **Type Protocol**: `{Feature}ViewModelType`
2. **Delegate Protocol**: `{Feature}ViewModelDelegate`

```swift
protocol DepositViewModelType: BaseViewModelType {
    var delegate: DepositViewModelDelegate? { get set }
    // Public interface
}

protocol DepositViewModelDelegate: AnyObject {
    // Callbacks to view
}

final class DepositViewModel: DepositViewModelType {
    weak var delegate: DepositViewModelDelegate?
    // Implementation
}
```

**ViewModel Responsibilities:**
- ✓ Presentation logic only
- ✓ Coordinate UseCases
- ✓ Transform domain data for display
- ✓ Manage view state

**ViewModel Must NOT:**
- ❌ Import UIKit
- ❌ Contain business logic (use UseCases)
- ❌ Directly call API services
- ❌ Manage view lifecycle

### UseCase Standards

**One UseCase = One Business Capability**

```swift
// ✅ GOOD: Single responsibility
class DepositAmountUseCase {
    // Only handles deposit amount validation
}

class BankAccountUseCase {
    // Only handles bank account operations
}

// ❌ BAD: Multiple responsibilities
class EwalletUseCase {
    // Handles everything - too broad
}
```

**UseCase Structure:**

```swift
class {Feature}UseCase {
    // MARK: - Dependencies (injected)
    private let apiService: ApiServiceType
    private let otherUC: OtherUseCase

    // MARK: - Initialization
    init(apiService: ApiServiceType, otherUC: OtherUseCase) {
        self.apiService = apiService
        self.otherUC = otherUC
    }

    // MARK: - Public Methods
    func performAction(
        parameters: ParamType,
        completion: @escaping (Result<DataType, ErrorType>) -> Void
    ) {
        // Business logic implementation
    }

    // MARK: - Private Helpers
    private func helperMethod() {
        // Internal logic
    }
}
```

## Memory Management Standards

### Delegate Pattern

**Always use `weak` for delegates:**

```swift
// ✅ CORRECT
protocol SomeDelegate: AnyObject { }

class SomeClass {
    weak var delegate: SomeDelegate?
}

// ❌ WRONG
class SomeClass {
    var delegate: SomeDelegate?  // Strong reference!
}
```

### Closure Capture Lists

**Use `[weak self]` in closures:**

```swift
// ✅ CORRECT
networkService.fetch { [weak self] result in
    guard let self = self else { return }
    self.handleResult(result)
}

// Alternative for non-escaping
someMethod { [weak self] in
    self?.updateUI()
}

// ❌ WRONG
networkService.fetch { result in
    self.handleResult(result)  // Retain cycle!
}
```

**When to use `unowned`:**
- Only when 100% certain object will outlive closure
- Rare cases in this codebase - prefer `weak`

### Timer and Observer Cleanup

```swift
class SomeViewModel {
    private var timer: Timer?
    private var observer: NSObjectProtocol?

    deinit {
        // ✅ Always cleanup
        timer?.invalidate()
        timer = nil

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

## Naming Conventions

### File Names

| Type | Pattern | Example |
|------|---------|---------|
| ViewModel | `{Feature}ViewModel.swift` | `DepositViewModel.swift` |
| ViewController | `{Feature}ViewController.swift` | `DepositViewController.swift` |
| UseCase | `{Feature}UseCase.swift` | `DepositAmountUseCase.swift` |
| DataSource | `{Feature}DataSource.swift` | `CardDataSource.swift` |
| DataCollector | `{Feature}Collector.swift` | `DepositCollector.swift` |
| Cell | `{Name}Cell.swift` | `AmountCell.swift` |
| Model | `{Name}.swift` | `BankAccount.swift` |

### Class and Protocol Names

```swift
// Protocols
protocol DepositViewModelType { }      // Interface
protocol DepositViewModelDelegate { }  // Delegate pattern
protocol ApiServiceType { }            // Service interface

// Classes
final class DepositViewModel { }       // Implementation
class DepositAmountUseCase { }         // UseCase
final class DepositViewController { }  // ViewController
```

### Variable Names

```swift
// UseCase instances: {name}UC
private let depositAmountUC: DepositAmountUseCase
private let bankAccountUC: BankAccountUseCase
private let settingsUC: SettingsUseCase

// Context
private let context: PayooEwalletContext

// Factory
private let vcFactory: ViewControllerType

// Avoid abbreviations
var bankAccount: BankAccount  // ✅ Good
var ba: BankAccount           // ❌ Bad
```

## Dependency Injection Standards

### Constructor Injection (Preferred)

```swift
final class DepositViewModel {
    private let depositAmountUC: DepositAmountUseCase
    private let bankAccountUC: BankAccountUseCase

    // ✅ All dependencies in initializer
    init(depositAmountUC: DepositAmountUseCase,
         bankAccountUC: BankAccountUseCase) {
        self.depositAmountUC = depositAmountUC
        self.bankAccountUC = bankAccountUC
    }
}
```

### Context Pattern

`PayooEwalletContext` is acceptable for shared dependencies:

```swift
final class SomeViewModel {
    private let context: PayooEwalletContext

    var balance: Double {
        return context.balanceInfo?.availableBalance ?? 0.0
    }
}
```

### What NOT to do

```swift
// ❌ Service locator
let service = ServiceLocator.shared.depositService

// ❌ Singletons (except system services)
let manager = NetworkManager.shared

// ❌ Creating dependencies inside
init() {
    self.service = NetworkService()  // Should be injected
}
```

## SwiftLint Standards

### Line Length
- **Maximum**: 120 characters
- Break long lines for readability

### File Length
- **Warning**: 500 lines
- **Error**: 1200 lines
- Split large files into extensions or separate files

### Type Body Length
- **Warning**: 300 lines
- **Error**: 400 lines
- Extract protocols, extensions to separate files

### Force Unwrapping
- **Avoid**: Only use `!` when 100% safe
- Prefer `guard let`, `if let`, or optional chaining

```swift
// ✅ GOOD
guard let value = optional else { return }

if let value = optional {
    use(value)
}

optional?.method()

// ❌ AVOID
let value = optional!
```

## API Design Standards

### Public SDK APIs

```swift
// ✅ Clear, descriptive method names
public func deposit(
    amount: Double,
    completion: @escaping (Result<DepositResult, DepositError>) -> Void
)

// ✅ Delegate pattern for callbacks
public protocol PayooEwalletDelegate: AnyObject {
    func ewalletDidComplete(result: EwalletResult)
    func ewalletDidFail(error: EwalletError)
}

// ✅ Typed errors
public enum DepositError: Error, LocalizedError {
    case insufficientBalance
    case invalidAmount
    case networkFailure(Error)
}
```

### Access Control

```swift
// Public API
public class PayooEwalletContext { }
public protocol PayooEwalletDelegate { }

// Internal (framework-only)
internal class NetworkService { }
internal struct Config { }

// Private (file-only)
private func helperMethod() { }
private let constant = "value"

// File-private (accessible in extensions)
fileprivate class InternalHelper { }
```

## Error Handling Standards

### Typed Errors with Localization

```swift
enum DepositError: Error, LocalizedError {
    case outOfRange(bank: String, min: Double, max: Double)
    case exceedMaxTimesDeposit(bankName: String, times: Int)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .outOfRange(let bank, let min, let max):
            return L10n.Message.Deposit.outOfRange(
                min.currencyString,
                max.currencyString,
                bank
            )
        case .exceedMaxTimesDeposit(let bankName, let times):
            return L10n.Message.Deposit.exceedMaxTimesDeposit(
                bankName,
                times
            )
        case .networkFailure(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .outOfRange:
            return L10n.Message.Deposit.adjustAmount
        default:
            return nil
        }
    }
}
```

### Result Type Pattern

```swift
// ✅ Preferred for async operations
func validateAmount(
    _ amount: Double,
    completion: @escaping (Result<Collector, DepositError>) -> Void
) {
    // Implementation
    completion(.success(collector))
    // or
    completion(.failure(.invalidAmount))
}
```

## Localization Standards

### SwiftGen Usage

All user-facing strings must use SwiftGen:

```swift
// ✅ CORRECT
let title = L10n.Deposit.Navigation.deposit
let message = L10n.Message.Deposit.outOfRange(min, max, bank)
let button = L10n.Btn.Title.confirm

// ❌ WRONG
let title = "Deposit"
let message = "Amount out of range"
```

### String Format

For strings with parameters:

```swift
// In Localizable.strings:
// "deposit.message.out_of_range" = "Amount must be between %@ and %@ for %@";

// In code:
L10n.Message.Deposit.outOfRange(
    minAmount.currencyString,
    maxAmount.currencyString,
    bankName
)
```

## Multi-Target Standards

### Internal/External Builds

```swift
#if INTERNAL
    // Internal-only features
    public func debugMode() {
        // Only available in internal builds
    }

    private func internalHelper() {
        // Internal tools
    }
#endif

// Always available
public func publicAPI() {
    #if INTERNAL
        enableDebugLogging()
    #endif

    // Public functionality
}
```

### Build Configuration

- **Internal Target**: Has `-D INTERNAL` flag in Swift Compiler settings
- **External Target**: No `INTERNAL` flag, same product name
- Check build settings: `Swift Compiler - Custom Flags`

## Testing Standards

### ViewModel Testing

```swift
final class DepositViewModelTests: XCTestCase {
    var sut: DepositViewModel!
    var mockDelegate: MockDepositViewModelDelegate!
    var mockDepositUC: MockDepositAmountUseCase!

    override func setUp() {
        super.setUp()
        mockDelegate = MockDepositViewModelDelegate()
        mockDepositUC = MockDepositAmountUseCase()
        sut = DepositViewModel(
            depositAmountUC: mockDepositUC,
            // ... other dependencies
        )
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut = nil
        mockDelegate = nil
        mockDepositUC = nil
        super.tearDown()
    }

    func testTopupSuccess() {
        // Given
        let amount = 100000.0
        mockDepositUC.shouldSucceed = true

        // When
        sut.topup(amount: amount)

        // Then
        XCTAssertTrue(mockDelegate.didShowConfirm)
        XCTAssertEqual(mockDelegate.confirmedAmount, amount)
    }
}
```

## Documentation Standards

### Public APIs

```swift
/// Initiates a deposit transaction for the specified amount.
///
/// This method validates the amount against the user's limits and
/// bank constraints before proceeding to the confirmation screen.
///
/// - Parameters:
///   - amount: The amount to deposit in VND
///   - completion: Called when validation completes
/// - Note: Requires user to be authenticated and KYC verified
/// - Important: Amount must be within bank-specific limits
public func deposit(
    amount: Double,
    completion: @escaping (Result<DepositResult, DepositError>) -> Void
)
```

### Complex Logic

```swift
// Complex algorithm - explain the approach
private func calculateFee(amount: Double) -> Double {
    // Fee structure:
    // - 0-1M: 1000 VND
    // - 1M-10M: 0.1%
    // - >10M: 0.05%
    // Minimum fee: 1000 VND

    guard amount > 0 else { return 0 }

    // Implementation...
}
```

## Git Standards

### Commit Messages

Follow project convention from [.gitlab-ci.yml](.gitlab-ci.yml):

```
[iOS][Framework Name][Category] Description

Examples:
[iOS][PayooEwallet][Feature] Add deposit fee calculator
[iOS][PayooCore][Fix] Fix memory leak in network client
[iOS][PayooPayment][Refactor] Extract payment validation to UseCase
```

### Branch Naming

From GitLab CI configuration:
- Feature branches: `feature/{issue-id}-description` or `{issue-id}-description`
- Release branches: `release/{milestone-id}` or `release/{version}`
- Bugfix branches: `fix/{issue-id}-description`

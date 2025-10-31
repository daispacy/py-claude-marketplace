# Clean Architecture Examples

Complete examples of proper layer separation, MVVM patterns, and dependency injection.

## Complete Architecture Example

### Proper 3-Layer Implementation

#### Presentation Layer - ViewModel
```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    // ✅ Depends only on UseCase (Domain layer)
    private let paymentUC: PaymentUseCase
    private let disposeBag = DisposeBag()

    // UI State
    let paymentAmount = BehaviorRelay<String>(value: "")
    let isProcessing = BehaviorRelay<Bool>(value: false)

    // ✅ Constructor injection
    init(paymentUC: PaymentUseCase) {
        self.paymentUC = paymentUC
        super.init()
    }

    func processPayment() {
        isProcessing.accept(true)

        // ✅ Delegates to UseCase, no business logic here
        paymentUC.execute(amount: paymentAmount.value)
            .subscribeOn(ConcurrentScheduler.background)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] result in
                    self?.setState(.success(result))
                },
                onError: { [weak self] error in
                    self?.setState(.error(error))
                },
                onCompleted: { [weak self] in
                    self?.isProcessing.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }
}
```

#### Domain Layer - UseCase
```swift
// ✅ Protocol in Domain layer
protocol PaymentUseCase {
    func execute(amount: String) -> Single<PaymentResult>
}

// ✅ Implementation in Domain layer
class PaymentUseCaseImpl: PaymentUseCase {
    // ✅ Depends on Repository protocol (Domain layer)
    private let paymentRepository: PaymentRepository
    private let validationService: ValidationService

    init(paymentRepository: PaymentRepository,
         validationService: ValidationService) {
        self.paymentRepository = paymentRepository
        self.validationService = validationService
    }

    func execute(amount: String) -> Single<PaymentResult> {
        // ✅ Business logic in UseCase
        return validationService.validateAmount(amount)
            .flatMap { validatedAmount in
                // ✅ Calls Repository, not API directly
                return self.paymentRepository.processPayment(amount: validatedAmount)
            }
            .map { response in
                // ✅ Business rules applied here
                return self.applyBusinessRules(response)
            }
    }

    private func applyBusinessRules(_ response: PaymentResponse) -> PaymentResult {
        // Business logic here
        return PaymentResult(from: response)
    }
}
```

#### Data Layer - Repository
```swift
// ✅ Protocol in Domain layer
protocol PaymentRepository {
    func processPayment(amount: Double) -> Single<PaymentResponse>
}

// ✅ Implementation in Data layer
class PaymentRepositoryImpl: PaymentRepository {
    private let apiService: PaymentApiService
    private let localStorage: PaymentLocalStorage

    init(apiService: PaymentApiService, localStorage: PaymentLocalStorage) {
        self.apiService = apiService
        self.localStorage = localStorage
    }

    func processPayment(amount: Double) -> Single<PaymentResponse> {
        // ✅ Data access only, no business logic
        return apiService.processPayment(amount: amount)
            .do(onSuccess: { [weak self] response in
                // Save to local storage
                self?.localStorage.savePaymentRecord(response)
            })
    }
}
```

#### DI Setup - Swinject
```swift
extension Container {
    func registerPaymentModule() {
        // Register Use Cases
        register(PaymentUseCase.self) { resolver in
            PaymentUseCaseImpl(
                paymentRepository: resolver.resolve(PaymentRepository.self)!,
                validationService: resolver.resolve(ValidationService.self)!
            )
        }

        // Register Repositories
        register(PaymentRepository.self) { resolver in
            PaymentRepositoryImpl(
                apiService: resolver.resolve(PaymentApiService.self)!,
                localStorage: resolver.resolve(PaymentLocalStorage.self)!
            )
        }

        // Register ViewModels
        register(PaymentViewModel.self) { resolver in
            PaymentViewModel(
                paymentUC: resolver.resolve(PaymentUseCase.self)!
            )
        }
    }
}
```

---

## Common Anti-Patterns

### ❌ Anti-Pattern 1: ViewModel Calling API Directly

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let apiService: PaymentApiService  // ❌ Wrong layer!

    func processPayment(amount: Double) {
        // ❌ Direct API call bypasses business logic
        apiService.processPayment(amount: amount)
            .subscribe(onNext: { result in
                // Handle result
            })
            .disposed(by: disposeBag)
    }
}
```

**Problems**:
- Business logic scattered or missing
- Hard to test
- Violates layer separation
- Cannot reuse logic elsewhere

**Fix**: Add UseCase layer
```swift
// 1. Create UseCase
protocol PaymentUseCase {
    func execute(amount: Double) -> Single<PaymentResult>
}

// 2. Update ViewModel
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let paymentUC: PaymentUseCase  // ✅ Correct!

    func processPayment(amount: Double) {
        paymentUC.execute(amount: amount)  // ✅ Through UseCase
            .subscribe(/* ... */)
            .disposed(by: disposeBag)
    }
}
```

---

### ❌ Anti-Pattern 2: Business Logic in ViewModel

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    func processPayment(amount: String) {
        // ❌ Validation logic in ViewModel
        guard let amt = Double(amount), amt > 1000 else {
            setState(.showError("Invalid amount"))
            return
        }

        // ❌ Business rules in ViewModel
        let fee = amt * 0.01
        let total = amt + fee

        if total > 50_000_000 {
            setState(.showError("Amount too high"))
            return
        }

        // Process...
    }
}
```

**Problems**:
- Cannot reuse validation/business logic
- Hard to test logic independently
- ViewModel becomes complex
- Violates Single Responsibility

**Fix**: Move to UseCase
```swift
// ✅ Business logic in UseCase
class PaymentUseCaseImpl: PaymentUseCase {
    func execute(amount: String) -> Single<PaymentResult> {
        return validateAmount(amount)
            .flatMap { validatedAmount in
                return self.calculateFeesAndProcess(validatedAmount)
            }
    }

    private func validateAmount(_ amount: String) -> Single<Double> {
        guard let amt = Double(amount), amt > 1000 else {
            return .error(PaymentError.invalidAmount)
        }

        let fee = amt * 0.01
        let total = amt + fee

        guard total <= 50_000_000 else {
            return .error(PaymentError.amountTooHigh)
        }

        return .just(amt)
    }
}

// ✅ ViewModel simplified
class PaymentViewModel: BaseViewModel<PaymentState> {
    func processPayment(amount: String) {
        paymentUC.execute(amount: amount)
            .subscribe(
                onNext: { [weak self] result in
                    self?.setState(.success(result))
                },
                onError: { [weak self] error in
                    self?.setState(.error(error))
                }
            )
            .disposed(by: disposeBag)
    }
}
```

---

### ❌ Anti-Pattern 3: UseCase Calling API Directly

```swift
class PaymentUseCaseImpl: PaymentUseCase {
    private let apiService: PaymentApiService  // ❌ Bypasses Repository!

    func execute(amount: Double) -> Single<PaymentResult> {
        // ❌ Direct API call
        return apiService.processPayment(amount: amount)
            .map { response in
                return PaymentResult(from: response)
            }
    }
}
```

**Problems**:
- Cannot swap data sources (API/local/mock)
- Hard to test independently
- Violates Dependency Inversion

**Fix**: Add Repository layer
```swift
// ✅ Repository protocol in Domain
protocol PaymentRepository {
    func processPayment(amount: Double) -> Single<PaymentResponse>
}

// ✅ UseCase depends on protocol
class PaymentUseCaseImpl: PaymentUseCase {
    private let paymentRepository: PaymentRepository  // ✅ Correct!

    func execute(amount: Double) -> Single<PaymentResult> {
        return paymentRepository.processPayment(amount: amount)
            .map { response in
                return PaymentResult(from: response)
            }
    }
}

// ✅ Implementation in Data layer
class PaymentRepositoryImpl: PaymentRepository {
    private let apiService: PaymentApiService

    func processPayment(amount: Double) -> Single<PaymentResponse> {
        return apiService.processPayment(amount: amount)
    }
}
```

---

## Refactoring Examples

### Example: Refactoring ViewModel with Business Logic

#### Before (Violates Clean Architecture)
```swift
class TransactionViewModel: BaseViewModel<TransactionState> {
    private let apiService: TransactionApiService

    func loadTransactions(from startDate: Date, to endDate: Date) {
        // ❌ Date validation in ViewModel
        guard startDate <= endDate else {
            setState(.showError("Invalid date range"))
            return
        }

        // ❌ Business rule in ViewModel
        let daysDiff = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
        guard daysDiff <= 90 else {
            setState(.showError("Date range too large"))
            return
        }

        // ❌ Direct API call
        apiService.getTransactions(from: startDate, to: endDate)
            .subscribe(onNext: { [weak self] transactions in
                // ❌ Business logic: filtering
                let filtered = transactions.filter { $0.amount > 0 }
                self?.transactions.accept(filtered)
            })
            .disposed(by: disposeBag)
    }
}
```

#### After (Clean Architecture)
```swift
// DOMAIN LAYER - UseCase
protocol TransactionUseCase {
    func getTransactions(from: Date, to: Date) -> Single<[Transaction]>
}

class TransactionUseCaseImpl: TransactionUseCase {
    private let repository: TransactionRepository

    func getTransactions(from startDate: Date, to endDate: Date) -> Single<[Transaction]> {
        // ✅ Validation in UseCase
        return validateDateRange(startDate, endDate)
            .flatMap { _ in
                return self.repository.getTransactions(from: startDate, to: endDate)
            }
            .map { transactions in
                // ✅ Business logic in UseCase
                return self.filterValidTransactions(transactions)
            }
    }

    private func validateDateRange(_ start: Date, _ end: Date) -> Single<Void> {
        guard start <= end else {
            return .error(TransactionError.invalidDateRange)
        }

        let daysDiff = Calendar.current.dateComponents([.day], from: start, to: end).day!
        guard daysDiff <= 90 else {
            return .error(TransactionError.dateRangeTooLarge)
        }

        return .just(())
    }

    private func filterValidTransactions(_ transactions: [Transaction]) -> [Transaction] {
        return transactions.filter { $0.amount > 0 }
    }
}

// PRESENTATION LAYER - ViewModel
class TransactionViewModel: BaseViewModel<TransactionState> {
    private let transactionUC: TransactionUseCase  // ✅ Depends on UseCase

    func loadTransactions(from startDate: Date, to endDate: Date) {
        // ✅ Simply delegates to UseCase
        transactionUC.getTransactions(from: startDate, to: endDate)
            .subscribe(
                onNext: { [weak self] transactions in
                    self?.transactions.accept(transactions)
                    self?.setState(.loaded)
                },
                onError: { [weak self] error in
                    self?.setState(.error(error))
                }
            )
            .disposed(by: disposeBag)
    }
}
```

**Benefits**:
- ✅ Clear separation of concerns
- ✅ Business logic testable in isolation
- ✅ ViewModel is simple coordinator
- ✅ Can reuse UseCase elsewhere

---

## Testing Benefits

### With Clean Architecture

```swift
class PaymentUseCaseTests: XCTestCase {
    func testExecute_WithValidAmount_ProcessesPayment() {
        // ✅ Can test UseCase in isolation
        let mockRepository = MockPaymentRepository()
        mockRepository.processPaymentResult = .just(PaymentResponse.success)

        let useCase = PaymentUseCaseImpl(paymentRepository: mockRepository)

        // Test business logic directly
        let result = try! useCase.execute(amount: "10000").toBlocking().first()!
        XCTAssertTrue(result.isSuccess)
    }

    func testExecute_WithInvalidAmount_ReturnsError() {
        let mockRepository = MockPaymentRepository()
        let useCase = PaymentUseCaseImpl(paymentRepository: mockRepository)

        // Test validation logic
        XCTAssertThrowsError(
            try useCase.execute(amount: "500").toBlocking().first()
        ) { error in
            XCTAssertEqual(error as? PaymentError, .invalidAmount)
        }
    }
}
```

### Without Clean Architecture

```swift
// ❌ Hard to test business logic without UI/Network
class PaymentViewModelTests: XCTestCase {
    func testProcessPayment() {
        // Need to mock UI, network, and test everything together
        // Business logic mixed with presentation logic
        // Hard to isolate what's being tested
    }
}
```

---

## Checklist for Reviews

```markdown
## Clean Architecture Checklist

### Layer Separation
- [ ] ViewModel only depends on UseCase (not API/Repository)
- [ ] UseCase contains all business logic
- [ ] UseCase only depends on Repository protocol
- [ ] Repository implementation is in Data layer
- [ ] No business logic in ViewModel
- [ ] No business logic in Repository
- [ ] No UI code in Domain/Data layers

### Patterns
- [ ] ViewModel extends BaseViewModel<State>
- [ ] UseCase follows protocol + implementation pattern
- [ ] Repository follows protocol + implementation pattern
- [ ] State management uses setState()

### Dependency Injection
- [ ] All dependencies injected via constructor
- [ ] No direct instantiation of dependencies
- [ ] Swinject container properly configured
- [ ] Dependencies are protocol-based (not concrete types)

### Data Flow
- [ ] UI → ViewController → ViewModel → UseCase → Repository → API/DB
- [ ] Never skips layers
- [ ] Observables/Singles for async operations
- [ ] Errors properly propagated through layers
```

# RxSwift Memory Check Examples

Detailed examples of memory leaks, retain cycles, and proper RxSwift memory management.

## Critical Issue Examples

### Example 1: Missing Disposal (Memory Leak)

#### ❌ Problem Code
```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let paymentUC: PaymentUseCase
    private let disposeBag = DisposeBag()

    func processPayment() {
        paymentUC.execute(amount: paymentAmount.value)
            .subscribe(onNext: { [weak self] result in
                self?.handleResult(result)
            })
            // ❌ MISSING: .disposed(by: disposeBag)
    }
}
```

**Problem**: Subscription never releases, accumulates in memory
**Impact**: Memory grows over time, eventually crashes app
**Symptoms**: Increasing memory usage, app slowdown

#### ✅ Fixed Code
```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let paymentUC: PaymentUseCase
    private let disposeBag = DisposeBag()

    func processPayment() {
        paymentUC.execute(amount: paymentAmount.value)
            .subscribe(onNext: { [weak self] result in
                self?.handleResult(result)
            })
            .disposed(by: disposeBag)  // ✅ Added
    }
}
```

**Fix**: Add `.disposed(by: disposeBag)` to every subscription
**Result**: Subscription properly cleaned up when ViewModel deallocates

---

### Example 2: Retain Cycle (Strong Self Reference)

#### ❌ Problem Code
```swift
class StoresViewModel: BaseViewModel<StoresState> {
    private let storesUC: StoresUseCase
    private let disposeBag = DisposeBag()

    let stores = BehaviorRelay<[Store]>(value: [])

    func loadStores() {
        storesUC.getStores()
            .subscribe(onNext: { stores in
                // ❌ Strong self reference - retain cycle!
                self.stores.accept(stores)
            })
            .disposed(by: disposeBag)
    }
}
```

**Problem**: Closure captures self strongly, creating retain cycle
**Impact**: ViewModel never deallocates, memory leak
**Symptoms**: View controllers don't deallocate, memory grows
**Detection**: Xcode Debug Memory Graph shows cycle

#### ✅ Fixed Code
```swift
class StoresViewModel: BaseViewModel<StoresState> {
    private let storesUC: StoresUseCase
    private let disposeBag = DisposeBag()

    let stores = BehaviorRelay<[Store]>(value: [])

    func loadStores() {
        storesUC.getStores()
            .subscribe(onNext: { [weak self] stores in
                // ✅ Weak self - no retain cycle
                self?.stores.accept(stores)
            })
            .disposed(by: disposeBag)
    }
}
```

**Fix**: Use `[weak self]` in closure capture list
**Result**: ViewModel can deallocate properly, no memory leak

---

### Example 3: Local DisposeBag (Early Cancellation)

#### ❌ Problem Code
```swift
class TransactionViewModel: BaseViewModel<TransactionState> {
    func loadTransactions() {
        let disposeBag = DisposeBag()  // ❌ Local variable!

        transactionUC.getTransactions()
            .subscribe(onNext: { [weak self] transactions in
                self?.handleTransactions(transactions)
            })
            .disposed(by: disposeBag)

        // ❌ disposeBag deallocates here, cancels subscription immediately!
    }
}
```

**Problem**: DisposeBag deallocates when function exits, canceling subscription
**Impact**: Observable never completes, callbacks never fire
**Symptoms**: Data doesn't load, UI doesn't update

#### ✅ Fixed Code
```swift
class TransactionViewModel: BaseViewModel<TransactionState> {
    private let disposeBag = DisposeBag()  // ✅ Property

    func loadTransactions() {
        transactionUC.getTransactions()
            .subscribe(onNext: { [weak self] transactions in
                self?.handleTransactions(transactions)
            })
            .disposed(by: disposeBag)  // ✅ Uses property
    }
}
```

**Fix**: Make DisposeBag a class property, not local variable
**Result**: Subscription lives as long as the ViewModel

---

### Example 4: Multiple DisposeBags (Anti-Pattern)

#### ❌ Problem Code
```swift
class DashboardViewModel: BaseViewModel<DashboardState> {
    private var searchDisposeBag = DisposeBag()  // ❌ Anti-pattern
    private var dataDisposeBag = DisposeBag()    // ❌ Anti-pattern
    private var uiDisposeBag = DisposeBag()      // ❌ Anti-pattern

    func search(query: String) {
        searchService.search(query)
            .subscribe(onNext: { results in })
            .disposed(by: searchDisposeBag)
    }

    func loadData() {
        dataService.loadData()
            .subscribe(onNext: { data in })
            .disposed(by: dataDisposeBag)
    }
}
```

**Problem**: Unnecessary complexity, harder to manage subscriptions
**Impact**: Confusing code, potential for errors

#### ✅ Fixed Code
```swift
class DashboardViewModel: BaseViewModel<DashboardState> {
    private let disposeBag = DisposeBag()  // ✅ Single DisposeBag

    func search(query: String) {
        searchService.search(query)
            .subscribe(onNext: { results in })
            .disposed(by: disposeBag)  // ✅ Same bag
    }

    func loadData() {
        dataService.loadData()
            .subscribe(onNext: { data in })
            .disposed(by: disposeBag)  // ✅ Same bag
    }
}
```

**Fix**: Use single DisposeBag per class
**Result**: Simpler code, all subscriptions disposed together

---

## Complete Examples

### Example 5: Proper RxSwift Memory Management

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    // Dependencies
    private let paymentUC: PaymentUseCase
    private let validationService: ValidationService

    // DisposeBag property (not local!)
    private let disposeBag = DisposeBag()

    // State
    let paymentAmount = BehaviorRelay<String>(value: "")
    let isProcessing = BehaviorRelay<Bool>(value: false)

    init(paymentUC: PaymentUseCase, validationService: ValidationService) {
        self.paymentUC = paymentUC
        self.validationService = validationService
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        // ✅ Proper disposal with weak self
        paymentAmount
            .map { [weak self] amount in
                self?.validationService.validateAmount(amount) ?? false
            }
            .subscribe(onNext: { [weak self] isValid in
                self?.setState(isValid ? .valid : .invalid)
            })
            .disposed(by: disposeBag)
    }

    func processPayment() {
        isProcessing.accept(true)

        paymentUC.execute(amount: paymentAmount.value)
            .subscribeOn(ConcurrentScheduler.background)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] result in
                    self?.handleSuccess(result)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                },
                onCompleted: { [weak self] in
                    self?.isProcessing.accept(false)
                }
            )
            .disposed(by: disposeBag)  // ✅ Always disposed
    }

    private func handleSuccess(_ result: PaymentResult) {
        setState(.success(result))
    }

    private func handleError(_ error: Error) {
        setState(.error(error))
        isProcessing.accept(false)
    }
}
```

**Key Points**:
- ✅ DisposeBag is a property
- ✅ Every subscription uses `.disposed(by:)`
- ✅ Every closure uses `[weak self]`
- ✅ Proper error handling
- ✅ Correct scheduler usage

---

### Example 6: ViewController with Proper Bindings

```swift
class PaymentViewController: UIViewController {
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    private let viewModel: PaymentViewModel
    private let disposeBag = DisposeBag()  // ✅ Property

    init(viewModel: PaymentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use dependency injection")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        title = "Payment"
    }

    private func bindViewModel() {
        // Input: TextField → ViewModel
        amountTextField.rx.text
            .orEmpty
            .bind(to: viewModel.paymentAmount)
            .disposed(by: disposeBag)  // ✅ Disposed

        // Input: Button tap → ViewModel action
        confirmButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.processPayment()
            })
            .disposed(by: disposeBag)  // ✅ Disposed

        // Output: ViewModel → UI
        viewModel.isProcessing
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)  // ✅ Disposed

        viewModel.isProcessing
            .map { !$0 }
            .bind(to: confirmButton.rx.isEnabled)
            .disposed(by: disposeBag)  // ✅ Disposed

        // State handling
        viewModel.getState()
            .compactMap { $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.handleState(state.name)
            })
            .disposed(by: disposeBag)  // ✅ Disposed
    }

    private func handleState(_ state: PaymentState) {
        switch state {
        case .success(let result):
            showSuccessAlert(result)
        case .error(let error):
            showErrorAlert(error)
        default:
            break
        }
    }
}
```

**Key Points**:
- ✅ Single DisposeBag for all bindings
- ✅ All UI bindings properly disposed
- ✅ Weak self in subscribe closures
- ✅ Clean separation of concerns

---

## Common Scenarios

### Scenario 1: Timer/Interval Observable

#### ❌ Problem
```swift
func startTimer() {
    Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] tick in
            self?.updateTime(tick)
        })
        // ❌ No disposal - timer runs forever!
}
```

#### ✅ Solution
```swift
class TimerViewModel {
    private let disposeBag = DisposeBag()

    func startTimer() {
        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] tick in
                self?.updateTime(tick)
            })
            .disposed(by: disposeBag)  // ✅ Stops when ViewModel deallocates
    }
}
```

---

### Scenario 2: Network Requests

#### ❌ Problem
```swift
func loadData() {
    networkService.fetchData()
        .subscribe(onNext: { data in
            self.data = data  // ❌ Strong self
        })
        // ❌ No disposal
}
```

#### ✅ Solution
```swift
class DataViewModel {
    private let disposeBag = DisposeBag()

    func loadData() {
        networkService.fetchData()
            .subscribe(
                onNext: { [weak self] data in
                    self?.data = data
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
}
```

---

### Scenario 3: Chained Observables

#### ❌ Problem
```swift
func processData() {
    fetchData()
        .flatMap { data in
            return self.transform(data)  // ❌ Strong self
        }
        .flatMap { transformed in
            return self.save(transformed)  // ❌ Strong self
        }
        .subscribe(onNext: { result in
            self.handleResult(result)  // ❌ Strong self
        })
        // ❌ No disposal
}
```

#### ✅ Solution
```swift
class DataProcessor {
    private let disposeBag = DisposeBag()

    func processData() {
        fetchData()
            .flatMap { [weak self] data -> Observable<TransformedData> in
                guard let self = self else { return .empty() }
                return self.transform(data)
            }
            .flatMap { [weak self] transformed -> Observable<Result> in
                guard let self = self else { return .empty() }
                return self.save(transformed)
            }
            .subscribe(
                onNext: { [weak self] result in
                    self?.handleResult(result)
                },
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
}
```

---

## Detection Tools

### Using Xcode Debug Memory Graph

1. Run app in Simulator/Device
2. Navigate to screen with suspected leak
3. Pop back
4. Xcode → Debug → View Memory Graph
5. Look for objects that should have deallocated
6. Check retain cycle graph

### Using Instruments

1. Product → Profile
2. Choose "Leaks" template
3. Record while using app
4. Navigate between screens
5. Check for red leak indicators
6. Inspect stack traces

### Manual Verification

Add `deinit` to ViewModels and ViewControllers:

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    deinit {
        print("✅ PaymentViewModel deallocated")  // Should print when leaving screen
    }
}

class PaymentViewController: UIViewController {
    deinit {
        print("✅ PaymentViewController deallocated")  // Should print when popping
    }
}
```

If `deinit` doesn't print, you have a memory leak!

---

## Quick Reference

### Memory Management Checklist

```markdown
## RxSwift Memory Check

For each Observable subscription:
- [ ] Has `.disposed(by: disposeBag)`
- [ ] Uses `[weak self]` in closures
- [ ] DisposeBag is a property (not local)
- [ ] No strong reference cycles
- [ ] Error handling present
- [ ] deinit prints when tested
```

### Common Patterns

| Pattern | Issue | Fix |
|---------|-------|-----|
| Missing disposal | Memory leak | Add `.disposed(by: disposeBag)` |
| Strong self | Retain cycle | Use `[weak self]` |
| Local DisposeBag | Early cancel | Make it a property |
| Multiple bags | Complexity | Use single DisposeBag |
| No error handling | Crashes | Add `onError` handler |

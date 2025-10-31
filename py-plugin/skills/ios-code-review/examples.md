# iOS Code Review Examples

Detailed examples for each review category with good/bad patterns.

## 1. Naming Conventions Examples

### ✅ Good Naming

```swift
// Classes and Types
class PaymentViewController: UIViewController { }
class RefundRequestViewModel: BaseViewModel<RefundRequestState> { }
protocol PaymentUseCase { }

// Variables and Properties
let paymentAmount = BehaviorRelay<String>(value: "")
let isProcessingPayment = BehaviorRelay<Bool>(value: false)
let transactions = BehaviorRelay<[Transaction]>(value: [])

// Functions
func loadTransactions() { }
func processPaymentRequest(amount: Double) { }
func validatePaymentAmount(_ amount: String) -> Bool { }

// IBOutlets
@IBOutlet weak var paymentAmountTextField: UITextField!
@IBOutlet weak var confirmButton: UIButton!
@IBOutlet weak var transactionTableView: UITableView!
```

### ❌ Bad Naming

```swift
// Classes - Too abbreviated or generic
class PayVC: UIViewController { }  // What is "Pay"?
class RefReqVM { }  // Too abbreviated
class Manager { }  // Too generic

// Variables - Unclear or abbreviated
let amt = BehaviorRelay<String>(value: "")  // What is "amt"?
let flag = BehaviorRelay<Bool>(value: false)  // Meaningless
let data = BehaviorRelay<[Any]>(value: [])  // Too generic

// Functions - Vague
func doSomething() { }  // What does it do?
func process() { }  // Process what?
func handle() { }  // Handle what?

// IBOutlets - Missing type suffix
@IBOutlet weak var amount: UITextField!  // Should be amountTextField
@IBOutlet weak var btn: UIButton!  // Should be confirmButton
```

---

## 2. RxSwift Pattern Examples

### ✅ Proper RxSwift Usage

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let paymentUC: PaymentUseCase
    private let disposeBag = DisposeBag()

    let paymentAmount = BehaviorRelay<String>(value: "")
    let isProcessing = BehaviorRelay<Bool>(value: false)

    init(paymentUC: PaymentUseCase) {
        self.paymentUC = paymentUC
        super.init()
    }

    func processPayment() {
        guard !paymentAmount.value.isEmpty else {
            setState(.showError(PaymentError.invalidAmount))
            return
        }

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
            .disposed(by: disposeBag)  // ✓ Proper disposal
    }
}
```

### ❌ Common RxSwift Mistakes

```swift
class PaymentViewModel: BaseViewModel<PaymentState> {
    // ❌ Missing DisposeBag property

    func processPayment() {
        // ❌ MEMORY LEAK: No disposal
        paymentUC.execute(amount: paymentAmount.value)
            .subscribe(onNext: { result in
                // ❌ RETAIN CYCLE: Strong self reference
                self.handleSuccess(result)
            })
            // MISSING: .disposed(by: disposeBag)
    }

    func loadData() {
        // ❌ Wrong scheduler for UI updates
        networkService.fetchData()
            .subscribeOn(MainScheduler.instance)  // Wrong!
            .subscribe(onNext: { data in
                self.tableView.reloadData()  // May be on background thread
            })
            .disposed(by: disposeBag)
    }

    func refreshData() {
        // ❌ No error handling
        dataSource.getData()
            .subscribe(onNext: { data in
                // Handle data
            })
            // MISSING: onError handler
            .disposed(by: disposeBag)
    }
}
```

### DisposeBag Anti-Patterns

```swift
// ❌ BAD: Local DisposeBag
func loadData() {
    let disposeBag = DisposeBag()  // Local variable!

    api.fetchData()
        .subscribe(onNext: { data in
            // Handle data
        })
        .disposed(by: disposeBag)
    // DisposeBag deallocates here, cancels subscription immediately!
}

// ❌ BAD: Multiple DisposeBags
class ViewModel {
    private var searchDisposeBag = DisposeBag()  // Anti-pattern
    private var dataDisposeBag = DisposeBag()    // Anti-pattern
}

// ✅ GOOD: Single DisposeBag property
class ViewModel {
    private let disposeBag = DisposeBag()  // Correct!
}
```

---

## 3. Clean Architecture Examples

### ✅ Proper Layer Separation

```swift
// PRESENTATION LAYER - ViewModel
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let paymentUC: PaymentUseCase  // ✓ Uses UseCase

    init(paymentUC: PaymentUseCase) {
        self.paymentUC = paymentUC
        super.init()
    }

    func processPayment(amount: String) {
        paymentUC.execute(amount: amount)  // ✓ Delegates to UseCase
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

// DOMAIN LAYER - UseCase
protocol PaymentUseCase {
    func execute(amount: String) -> Single<PaymentResult>
}

class PaymentUseCaseImpl: PaymentUseCase {
    private let paymentRepository: PaymentRepository
    private let validationService: ValidationService

    init(paymentRepository: PaymentRepository,
         validationService: ValidationService) {
        self.paymentRepository = paymentRepository
        self.validationService = validationService
    }

    func execute(amount: String) -> Single<PaymentResult> {
        // ✓ Business logic in UseCase
        return validationService.validateAmount(amount)
            .flatMap { validAmount in
                return self.paymentRepository.processPayment(amount: validAmount)
            }
    }
}

// DATA LAYER - Repository
protocol PaymentRepository {
    func processPayment(amount: Double) -> Single<PaymentResult>
}

class PaymentRepositoryImpl: PaymentRepository {
    private let apiService: PaymentApiService
    private let localStorage: PaymentLocalStorage

    func processPayment(amount: Double) -> Single<PaymentResult> {
        return apiService.processPayment(amount: amount)
            .do(onSuccess: { [weak self] result in
                self?.localStorage.savePaymentRecord(result)
            })
    }
}
```

### ❌ Layer Violations

```swift
// ❌ BAD: ViewModel bypassing UseCase
class PaymentViewModel: BaseViewModel<PaymentState> {
    private let apiService: PaymentApiService  // ❌ Wrong layer!

    func processPayment() {
        // ❌ Direct API call, no business logic
        apiService.processPayment(amount: amount)
            .subscribe(onNext: { result in
                // ❌ Direct storage access
                RealmManager.shared.save(result)
            })
            .disposed(by: disposeBag)
    }
}

// ❌ BAD: Business logic in ViewModel
class PaymentViewModel: BaseViewModel<PaymentState> {
    func processPayment(amount: Double) {
        // ❌ Validation logic in ViewModel
        guard amount > 1000 else { return }
        guard amount < 50_000_000 else { return }

        // ❌ Business rules in ViewModel
        let fee = amount * 0.01
        let total = amount + fee

        // This should all be in UseCase!
    }
}

// ❌ BAD: Direct instantiation
class PaymentViewController: UIViewController {
    // ❌ Hard-coded dependencies
    private let viewModel = PaymentViewModel(
        paymentUC: PaymentUseCaseImpl()  // ❌ Direct instantiation
    )
}
```

---

## 4. Security Examples

### ✅ Secure Payment Handling

```swift
class PaymentSecurityManager {
    private let keychain = KeychainWrapper.standard

    // ✓ Store in Keychain
    func storePaymentToken(_ token: String, for merchantId: String) {
        let key = "payment_token_\(merchantId)"
        keychain.set(token, forKey: key,
                    withAccessibility: .whenUnlockedThisDeviceOnly)
    }

    func retrievePaymentToken(for merchantId: String) -> String? {
        let key = "payment_token_\(merchantId)"
        return keychain.string(forKey: key)
    }
}

// ✓ Mask sensitive data in logs
class PaymentRequest {
    let amount: Double
    let merchantId: String

    override var description: String {
        return "PaymentRequest(amount: \(amount), merchantId: ***)"
    }
}

// ✓ HTTPS with certificate pinning
class PaymentNetworkManager {
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(
            configuration: config,
            delegate: CertificatePinningDelegate(),
            delegateQueue: nil
        )
    }()
}
```

### ❌ Security Violations

```swift
// ❌ BAD: Insecure storage
class PaymentManager {
    func storePaymentToken(_ token: String) {
        // ❌ UserDefaults is not secure!
        UserDefaults.standard.set(token, forKey: "payment_token")
    }

    func processPayment(_ request: PaymentRequest) {
        // ❌ Logging sensitive data!
        print("Processing payment: \(request)")
        print("Card number: \(request.cardNumber)")
    }
}

// ❌ BAD: No certificate pinning
class PaymentNetworkManager {
    func processPayment(_ request: PaymentRequest) {
        let url = URL(string: "http://api.payoo.vn/payment")!  // ❌ HTTP!

        // ❌ No encryption
        let data = try! JSONEncoder().encode(request)

        // ❌ No certificate pinning
        URLSession.shared.dataTask(with: url) { _, _, _ in }
    }
}
```

---

## 5. UI/UX Examples

### ✅ Proper Navigation Setup

```swift
// ✓ Simple title
class PaymentViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Payment"  // ✓ Use title property
    }
}

// ✓ Title with subtitle (only when subtitle exists)
class StoreSelectionViewController: UIViewController {
    private let titleDescription: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let description = titleDescription, !description.isEmpty {
            // ✓ Only use titleView when subtitle exists
            navigationItem.titleView = createTitleView(
                title: "Store Selection",
                description: description
            )
        } else {
            // ✓ Use simple title when no subtitle
            title = "Store Selection"
        }
    }
}

// ✓ Loading states with feedback
class QRSaleViewController: UIViewController {
    private func bindLoadingStates() {
        viewModel.isProcessing
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.isProcessing
            .map { !$0 }
            .bind(to: processButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.isProcessing
            .map { $0 ? "Processing..." : "Process Payment" }
            .bind(to: processButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
    }
}

// ✓ Accessibility
class PaymentAmountView: UIView {
    private func setupAccessibility() {
        amountTextField.isAccessibilityElement = true
        amountTextField.accessibilityLabel = "Payment amount"
        amountTextField.accessibilityHint = "Enter the payment amount in VND"

        // ✓ Dynamic Type support
        amountTextField.font = UIFont.preferredFont(forTextStyle: .title2)
        amountTextField.adjustsFontForContentSizeCategory = true
    }
}
```

### ❌ UI/UX Issues

```swift
// ❌ BAD: Using titleView for simple title
class PaymentViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // ❌ Unnecessary custom title view
        let titleLabel = UILabel()
        titleLabel.text = "Payment"
        navigationItem.titleView = titleLabel  // Should use title property!
    }
}

// ❌ BAD: No loading feedback
class QRSaleViewController: UIViewController {
    private func processPayment() {
        // ❌ No loading indicator
        viewModel.processPayment()  // User has no feedback!
    }
}

// ❌ BAD: No accessibility
class PaymentAmountView: UIView {
    // ❌ No accessibility setup
    // ❌ No Dynamic Type support
    // ❌ Missing accessibility labels
}
```

---

## 6. Performance Examples

### ✅ Proper Memory Management

```swift
class ImageDownloadManager {
    private let cache = NSCache<NSString, UIImage>()
    private var activeDownloads: [String: Disposable] = [:]

    func downloadImage(from url: String) -> Observable<UIImage> {
        let cacheKey = url as NSString

        // ✓ Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return .just(cachedImage)
        }

        // ✓ Cancel existing download
        activeDownloads[url]?.dispose()

        let download = URLSession.shared.rx
            .data(request: URLRequest(url: URL(string: url)!))
            .compactMap { UIImage(data: $0) }
            .do(
                onNext: { [weak self] image in
                    self?.cache.setObject(image, forKey: cacheKey)
                },
                onDispose: { [weak self] in
                    self?.activeDownloads.removeValue(forKey: url)
                }
            )
            .share(replay: 1, scope: .whileConnected)

        activeDownloads[url] = download.connect()
        return download
    }
}

// ✓ Database on background thread
class TransactionRepository {
    func getTransactions() -> Observable<[Transaction]> {
        return Observable.collection(from: realm.objects(TransactionObject.self))
            .map { results in
                return results.map { Transaction(from: $0) }
            }
            .subscribeOn(ConcurrentScheduler.background)  // ✓ Background
            .observeOn(MainScheduler.instance)  // ✓ Main for UI
    }
}
```

### ❌ Performance Issues

```swift
// ❌ BAD: Memory leak from strong references
class ImageDownloadManager {
    private var downloads: [URLSessionDataTask] = []  // ❌ Strong references

    func downloadImage(from url: String) -> Observable<UIImage> {
        return Observable.create { observer in
            let task = URLSession.shared.dataTask(with: URL(string: url)!) { data, _, _ in
                // Process
            }

            self.downloads.append(task)  // ❌ Never removed - leak!
            task.resume()

            return Disposables.create {
                task.cancel()
                // ❌ Still in downloads array!
            }
        }
    }
}

// ❌ BAD: Blocking main thread
class TransactionRepository {
    func getTransactions() -> Observable<[Transaction]> {
        return Observable.create { observer in
            // ❌ Blocking operation on main thread!
            let realm = try! Realm()
            let results = realm.objects(TransactionObject.self)
            let transactions = results.map { Transaction(from: $0) }

            observer.onNext(Array(transactions))
            observer.onCompleted()

            return Disposables.create()
        }
    }
}
```

---

## Common Review Scenarios

### Scenario 1: New Feature Review

**Code**: New payment processing feature

**Check**:
1. Naming: All classes/variables descriptive?
2. RxSwift: Disposal and memory management?
3. Architecture: Proper layer separation?
4. Security: Payment data handled securely?
5. Tests: Unit tests included?
6. Performance: No blocking operations?

### Scenario 2: Bug Fix Review

**Code**: Fix for crash in transaction list

**Check**:
1. Root cause addressed?
2. No force unwrapping?
3. Proper error handling added?
4. Tests for the bug scenario?
5. No new issues introduced?

### Scenario 3: Refactoring Review

**Code**: Refactor ViewModel to use Clean Architecture

**Check**:
1. UseCase layer added?
2. Business logic moved from ViewModel?
3. DI setup correctly?
4. Tests still pass?
5. No breaking changes?

---

**Detailed Examples**: See `examples.md` for extensive code samples and scenarios.

## Quick Reference Checklist

Copy this for quick reviews:

```markdown
## Review Checklist

### Naming ✅
- [ ] Classes: PascalCase, descriptive
- [ ] Variables: camelCase, meaningful
- [ ] Booleans: is/has/should/can prefix
- [ ] No abbreviations
- [ ] IBOutlets: type suffix

### RxSwift 🔄
- [ ] All subscriptions disposed
- [ ] [weak self] in closures
- [ ] Correct schedulers
- [ ] Error handling present
- [ ] Using BehaviorRelay

### Architecture 🏗️
- [ ] ViewModel → UseCase → Repository
- [ ] No business logic in ViewModel
- [ ] Dependencies injected
- [ ] BaseViewModel extended
- [ ] Repository pattern used

### Security 🔒
- [ ] Payment data in Keychain
- [ ] No sensitive logs
- [ ] HTTPS with pinning
- [ ] Input validation

### UI/UX 🎨
- [ ] title for simple titles
- [ ] titleView only with subtitle
- [ ] Accessibility configured
- [ ] Loading states shown

### Performance ⚡
- [ ] DB on background thread
- [ ] No retain cycles
- [ ] Image caching
- [ ] Memory management proper
```

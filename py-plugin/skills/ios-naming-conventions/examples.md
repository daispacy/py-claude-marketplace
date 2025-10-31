# iOS Naming Conventions Examples

Comprehensive examples of good and bad naming patterns in Swift.

## Classes and Types

### ✅ Good Examples
```swift
// View Controllers
class PaymentViewController: UIViewController { }
class TransactionListViewController: UIViewController { }
class RefundConfirmationViewController: UIViewController { }

// ViewModels
class PaymentViewModel: BaseViewModel<PaymentState> { }
class StoresViewModel: BaseViewModel<StoresState> { }
class TransactionHistoryViewModel: BaseViewModel<TransactionHistoryState> { }

// Use Cases
protocol PaymentUseCase { }
class PaymentUseCaseImpl: PaymentUseCase { }
protocol RefundRequestUseCase { }

// Repositories
protocol PaymentRepository { }
class PaymentRepositoryImpl: PaymentRepository { }

// Models
struct Transaction { }
struct PaymentRequest { }
struct RefundRequest { }

// Enums
enum PaymentMethod { }
enum TransactionStatus { }
enum RefundRequestError: Error { }
```

### ❌ Bad Examples
```swift
// Too abbreviated
class PayVC: UIViewController { }           // → PaymentViewController
class RefReqVM { }                          // → RefundRequestViewModel
class TrxRepo { }                           // → TransactionRepository

// Too generic
class Manager { }                           // → PaymentManager or specific purpose
class Helper { }                            // → ValidationHelper or specific purpose
class Util { }                              // → DateFormatter or specific utility

// Missing suffixes
class Payment { }                           // → PaymentViewModel or PaymentUseCase
class Transaction { }                       // If it's a ViewModel → TransactionViewModel
```

---

## Variables and Properties

### ✅ Good Examples
```swift
class PaymentViewModel {
    // State properties - descriptive
    let paymentAmount = BehaviorRelay<String>(value: "")
    let selectedPaymentMethod = BehaviorRelay<PaymentMethod?>(value: nil)
    let transactionResult = BehaviorRelay<TransactionResult?>(value: nil)

    // Boolean properties - with prefixes
    let isProcessingPayment = BehaviorRelay<Bool>(value: false)
    let hasNetworkConnection = BehaviorRelay<Bool>(value: true)
    let shouldShowError = BehaviorRelay<Bool>(value: false)
    let canSubmitPayment = BehaviorRelay<Bool>(value: false)

    // Collections - plural
    let transactions = BehaviorRelay<[Transaction]>(value: [])
    let errorMessages = BehaviorRelay<[String]>(value: [])
    let availablePaymentMethods = BehaviorRelay<[PaymentMethod]>(value: [])

    // Dependencies - full names
    private let paymentUseCase: PaymentUseCase
    private let validationService: ValidationService
    private let disposeBag = DisposeBag()
}
```

### ❌ Bad Examples
```swift
class PaymentViewModel {
    // Abbreviated
    let amt = BehaviorRelay<String>(value: "")           // → paymentAmount
    let pmtMethod = BehaviorRelay<PaymentMethod?>(value: nil)  // → paymentMethod
    let trxResult = BehaviorRelay<TransactionResult?>(value: nil)  // → transactionResult

    // Generic/meaningless
    let flag = BehaviorRelay<Bool>(value: false)         // → isProcessing
    let data = BehaviorRelay<[Any]>(value: [])           // → transactions
    let temp = BehaviorRelay<String>(value: "")          // → What is this?

    // Boolean without prefix
    let loading: Bool                                     // → isLoading
    let valid: Bool                                       // → isValid
    let enabled: Bool                                     // → isEnabled

    // Single letter
    let x = 0                                             // → transactionCount
    let a = amount                                        // → paymentAmount

    // Inconsistent abbreviations
    let paymentUC: PaymentUseCase                        // → paymentUseCase
}
```

---

## Functions and Methods

### ✅ Good Examples
```swift
class TransactionViewModel {
    // Actions - verb-based, descriptive
    func loadTransactions() { }
    func refreshTransactionList() { }
    func filterTransactionsByDate(from startDate: Date, to endDate: Date) { }
    func processRefundRequest(for transactionId: String) { }
    func validatePaymentAmount(_ amount: String) -> Bool { }

    // Queries - return information
    func getTransaction(by id: String) -> Transaction? { }
    func calculateTotalAmount(for transactions: [Transaction]) -> Double { }
    func hasUnprocessedTransactions() -> Bool { }
    func isValidPaymentAmount(_ amount: String) -> Bool { }

    // State handlers - clear purpose
    func handlePaymentSuccess(_ result: PaymentResult) { }
    func handlePaymentError(_ error: Error) { }
    func handleNetworkConnectionLost() { }

    // Setup/Configuration - clear intent
    func setupUI() { }
    func configureTableView() { }
    func bindViewModel() { }
}
```

### ❌ Bad Examples
```swift
class TransactionViewModel {
    // Too vague
    func doSomething() { }                    // → processRefundRequest()
    func process() { }                        // Process what? → processPayment()
    func get() { }                            // Get what? → getTransactions()
    func handle() { }                         // Handle what? → handleError()
    func go() { }                             // Go where? → navigateToDetails()

    // Noun-based instead of verb-based
    func transaction() { }                    // → loadTransaction() or getTransaction()
    func payment() { }                        // → processPayment()

    // Abbreviated
    func procPmt() { }                        // → processPayment()
    func getTrx() { }                         // → getTransaction()
    func valAmt(_ amt: String) { }            // → validateAmount(_ amount: String)
}
```

---

## IBOutlets

### ✅ Good Examples
```swift
class PaymentViewController: UIViewController {
    // Text fields - with TextField suffix
    @IBOutlet weak var paymentAmountTextField: UITextField!
    @IBOutlet weak var merchantCodeTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!

    // Labels - with Label suffix
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel!

    // Buttons - with Button suffix
    @IBOutlet weak var confirmPaymentButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!

    // Tables and collections - with TableView/CollectionView suffix
    @IBOutlet weak var transactionTableView: UITableView!
    @IBOutlet weak var storesCollectionView: UICollectionView!

    // Other views - with type suffix
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerContainerView: UIView!
    @IBOutlet weak var paymentMethodSegmentedControl: UISegmentedControl!
}
```

### ❌ Bad Examples
```swift
class PaymentViewController: UIViewController {
    // Missing type suffix
    @IBOutlet weak var amount: UITextField!        // → amountTextField
    @IBOutlet weak var currency: UILabel!          // → currencyLabel
    @IBOutlet weak var confirm: UIButton!          // → confirmButton

    // Abbreviated
    @IBOutlet weak var lbl: UILabel!               // → titleLabel
    @IBOutlet weak var btn: UIButton!              // → submitButton
    @IBOutlet weak var txtField: UITextField!      // → amountTextField

    // Too generic
    @IBOutlet weak var table: UITableView!         // → transactionTableView
    @IBOutlet weak var view: UIView!               // → headerView
    @IBOutlet weak var loading: UIActivityIndicatorView!  // → loadingIndicator
}
```

---

## Test Naming

### ✅ Good Examples
```swift
class PaymentViewModelTests: XCTestCase {
    // Format: test[MethodName]_[Scenario]_[ExpectedResult]

    func testProcessPayment_WithValidAmount_CompletesSuccessfully() { }
    func testProcessPayment_WithEmptyAmount_ShowsValidationError() { }
    func testProcessPayment_WithNetworkError_ShowsErrorState() { }
    func testLoadTransactions_WithCachedData_ReturnsDataImmediately() { }
    func testRefundRequest_WhenAmountExceedsTransaction_Fails() { }

    func testValidateAmount_BelowMinimum_ReturnsFalse() { }
    func testValidateAmount_AboveMaximum_ReturnsFalse() { }
    func testValidateAmount_ValidRange_ReturnsTrue() { }

    func testSubmitRefund_WithValidData_UpdatesStateToSuccess() { }
    func testSubmitRefund_WithInvalidData_UpdatesStateToError() { }
}
```

### ❌ Bad Examples
```swift
class PaymentViewModelTests: XCTestCase {
    func test1() { }                           // Meaningless number
    func testPayment() { }                     // Too vague
    func testError() { }                       // What error scenario?
    func testStuff() { }                       // Meaningless
    func test_payment_works() { }              // snake_case (wrong)
}
```

---

## Complete Class Examples

### ✅ Well-Named Class
```swift
class PaymentProcessingViewModel: BaseViewModel<PaymentState> {
    // Dependencies - full, descriptive names
    private let paymentUseCase: PaymentUseCase
    private let validationService: ValidationService
    private let disposeBag = DisposeBag()

    // Input properties - clear, descriptive
    let paymentAmount = BehaviorRelay<String>(value: "")
    let selectedMerchantId = BehaviorRelay<String?>(value: nil)
    let additionalNotes = BehaviorRelay<String>(value: "")

    // State properties - boolean with prefixes
    let isProcessingPayment = BehaviorRelay<Bool>(value: false)
    let hasValidPaymentAmount = BehaviorRelay<Bool>(value: false)
    let shouldEnableSubmitButton = BehaviorRelay<Bool>(value: false)

    // Output properties - descriptive
    let paymentResult = BehaviorRelay<PaymentResult?>(value: nil)
    let errorMessage = BehaviorRelay<String?>(value: nil)

    // Initializer - parameter names match properties
    init(paymentUseCase: PaymentUseCase, validationService: ValidationService) {
        self.paymentUseCase = paymentUseCase
        self.validationService = validationService
        super.init()
        setupValidation()
    }

    // Methods - verb-based, descriptive
    func processPaymentRequest() { }
    func validatePaymentAmount() -> Bool { }
    func clearPaymentForm() { }
    func handlePaymentSuccess(_ result: PaymentResult) { }
    func handlePaymentError(_ error: Error) { }

    private func setupValidation() { }
    private func updateSubmitButtonState() { }
}
```

### ❌ Poorly Named Class
```swift
class PaymentVM: BaseViewModel<PaymentState> {  // Abbreviated
    // Abbreviated dependencies
    private let pmtUC: PaymentUseCase            // → paymentUseCase
    private let valService: ValidationService    // → validationService
    private let bag = DisposeBag()               // → disposeBag

    // Abbreviated/unclear properties
    let amt = BehaviorRelay<String>(value: "")   // → paymentAmount
    let mid = BehaviorRelay<String?>(value: nil) // → merchantId
    let notes = BehaviorRelay<String>(value: "")  // Could be clearer

    // Boolean without prefix
    let processing = BehaviorRelay<Bool>(value: false)  // → isProcessing
    let valid = BehaviorRelay<Bool>(value: false)       // → hasValidAmount

    // Generic names
    let result = BehaviorRelay<PaymentResult?>(value: nil)  // → paymentResult
    let error = BehaviorRelay<String?>(value: nil)          // → errorMessage

    // Abbreviated initializer
    init(uc: PaymentUseCase, val: ValidationService) {      // Bad parameter names
        self.pmtUC = uc
        self.valService = val
        super.init()
    }

    // Vague method names
    func process() { }                           // → processPaymentRequest()
    func validate() -> Bool { }                  // → validatePaymentAmount()
    func clear() { }                             // → clearPaymentForm()
    func handle(_ r: PaymentResult) { }          // → handlePaymentSuccess()
}
```

---

## Refactoring Examples

### Example: Refactoring Poor Names

#### Before (Bad)
```swift
class TrxVM: BaseViewModel<TrxState> {
    let trxs = BehaviorRelay<[Trx]>(value: [])
    let loading = BehaviorRelay<Bool>(value: false)

    func getTrx(id: String) -> Trx? {
        return trxs.value.first { $0.id == id }
    }

    func proc() {
        loading.accept(true)
        // Process transactions
    }
}
```

#### After (Good)
```swift
class TransactionViewModel: BaseViewModel<TransactionState> {
    let transactions = BehaviorRelay<[Transaction]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)

    func getTransaction(by id: String) -> Transaction? {
        return transactions.value.first { $0.id == id }
    }

    func processTransactions() {
        isLoading.accept(true)
        // Process transactions
    }
}
```

**Changes Made**:
1. `TrxVM` → `TransactionViewModel` (full names, proper suffix)
2. `trxs` → `transactions` (no abbreviation, plural)
3. `loading` → `isLoading` (boolean prefix)
4. `getTrx` → `getTransaction` (full name, clear parameters)
5. `proc` → `processTransactions` (verb-based, descriptive)

---

## Quick Reference Checklist

Use this when reviewing naming:

```markdown
## Naming Conventions Checklist

### Classes/Structs/Enums
- [ ] PascalCase
- [ ] Descriptive and meaningful
- [ ] Proper suffix (ViewModel, UseCase, etc.)
- [ ] No abbreviations

### Variables/Properties
- [ ] camelCase
- [ ] Meaningful names
- [ ] Booleans have is/has/should/can prefix
- [ ] Collections are plural
- [ ] No single letters (except loops)
- [ ] No abbreviations

### Functions/Methods
- [ ] camelCase
- [ ] Verb-based (actions) or get/has/is (queries)
- [ ] Descriptive of purpose
- [ ] Clear parameter names

### IBOutlets
- [ ] Include type suffix
- [ ] Descriptive of purpose
- [ ] camelCase

### General
- [ ] No generic names (Manager, Helper, Util)
- [ ] Consistent naming style
- [ ] Easy to understand without context
```

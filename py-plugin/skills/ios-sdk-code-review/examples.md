# Code Review Examples

Real-world examples of good and bad patterns from iOS SDK development.

## Example 1: ViewModel Pattern

### ✅ GOOD Example

```swift
// DepositViewModel.swift

protocol DepositViewModelType: BaseViewModelType {
    var delegate: DepositViewModelDelegate? { get set }
    var balance: Double { get }
    func topup(amount: Double)
}

protocol DepositViewModelDelegate: AnyObject {
    func showError(_ error: EwalletError)
    func updateLimitInfo(min: Double, max: Double)
    func showDepositConfirm(collector: DepositDataCollector)
}

final class DepositViewModel: DepositViewModelType {
    weak var delegate: DepositViewModelDelegate?
    private let context: PayooEwalletContext
    private let depositAmountUC: DepositAmountUseCase
    private let bankAccountUC: BankAccountUseCase

    var balance: Double {
        return context.balanceInfo?.availableBalance ?? 0.0
    }

    init(context: PayooEwalletContext,
         depositAmountUC: DepositAmountUseCase,
         bankAccountUC: BankAccountUseCase) {
        self.context = context
        self.depositAmountUC = depositAmountUC
        self.bankAccountUC = bankAccountUC
    }

    func topup(amount: Double) {
        depositAmountUC.validateAmount(amount) { [weak self] result in
            switch result {
            case .success(let collector):
                self?.delegate?.showDepositConfirm(collector: collector)
            case .failure(let error):
                self?.delegate?.showError(error)
            }
        }
    }
}
```

**Why this is good:**
- ✓ Protocol-based design
- ✓ Weak delegate to prevent retain cycles
- ✓ Constructor injection
- ✓ Uses UseCases for business logic
- ✓ `[weak self]` in closures
- ✓ No UIKit dependencies
- ✓ Testable

### ❌ BAD Example

```swift
final class DepositViewModel {
    var delegate: DepositViewModelDelegate?  // ❌ Not weak

    init() {  // ❌ No dependency injection
        // Creating dependencies internally
    }

    func topup(amount: Double) {
        // ❌ Business logic in ViewModel
        let service = NetworkService.shared  // ❌ Singleton
        service.deposit(amount: amount) { data in  // ❌ Strong self capture
            self.delegate?.showConfirm()
        }
    }
}
```

**Problems:**
- ❌ Strong delegate reference (retain cycle)
- ❌ No dependency injection
- ❌ Business logic in ViewModel (should be in UseCase)
- ❌ Using singleton directly
- ❌ Strong self capture in closure
- ❌ No protocol definition
- ❌ Hard to test

## Example 2: UseCase Pattern

### ✅ GOOD Example

```swift
// DepositAmountUseCase.swift

class DepositAmountUseCase {
    private let apiService: ApiServiceType
    private let settingUC: SettingsUseCase

    enum DepositError: Error, LocalizedError {
        case outOfRange(bank: String, min: Double, max: Double)
        case exceedMaxTimesDeposit(bankName: String, times: Int)

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
            }
        }
    }

    init(apiService: ApiServiceType, settingUC: SettingsUseCase) {
        self.apiService = apiService
        self.settingUC = settingUC
    }

    func validateAmount(
        _ amount: Double,
        completion: @escaping (Result<DepositDataCollector, DepositError>) -> Void
    ) {
        let limits = settingUC.getDepositLimits()

        guard amount >= limits.min && amount <= limits.max else {
            completion(.failure(.outOfRange(
                bank: limits.bankName,
                min: limits.min,
                max: limits.max
            )))
            return
        }

        // Additional validation logic...
        let collector = DepositDataCollector(amount: amount)
        completion(.success(collector))
    }
}
```

**Why this is good:**
- ✓ Single responsibility (deposit validation)
- ✓ Injected dependencies
- ✓ Typed, localized errors
- ✓ Clean API with Result type
- ✓ No UIKit dependencies
- ✓ Testable

### ❌ BAD Example

```swift
class DepositUseCase {
    // ❌ No dependency injection
    func validateAndDeposit(_ amount: Double) {
        // ❌ Multiple responsibilities
        // ❌ Direct service access
        let service = APIService()

        // ❌ Generic error
        guard amount > 0 else {
            throw NSError(domain: "Invalid", code: -1)
        }

        // ❌ Hardcoded string
        print("Validating amount")

        // ❌ Mixing concerns
        UIAlertController.show(message: "Success")
    }
}
```

## Example 3: Memory Management

### ✅ GOOD Example

```swift
final class WithdrawViewModel {
    weak var delegate: WithdrawViewModelDelegate?
    private let withdrawUC: WithdrawUseCase
    private var timer: Timer?

    init(withdrawUC: WithdrawUseCase) {
        self.withdrawUC = withdrawUC
    }

    func startPolling() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: true
        ) { [weak self] _ in
            self?.checkStatus()
        }
    }

    func checkStatus() {
        withdrawUC.getStatus { [weak self] result in
            guard let self = self else { return }
            self.handleResult(result)
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}
```

**Why this is good:**
- ✓ Weak delegate
- ✓ `[weak self]` in closures
- ✓ Proper cleanup in `deinit`
- ✓ No retain cycles

### ❌ BAD Example

```swift
class WithdrawViewModel {
    var delegate: WithdrawViewModelDelegate?  // ❌ Strong reference
    private var timer: Timer?

    func startPolling() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: true
        ) { _ in
            self.checkStatus()  // ❌ Implicit strong self capture
        }
    }

    func checkStatus() {
        service.getStatus { result in  // ❌ Strong self capture
            self.delegate?.update(result)
        }
    }

    // ❌ No cleanup - timer keeps running
}
```

## Example 4: ViewController Pattern

### ✅ GOOD Example

```swift
final class DepositViewController: FirstViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var balanceLabel: UILabel!

    private var viewModel: DepositViewModelType
    private let vcFactory: ViewControllerType

    init(context: PayooEwalletContext,
         viewModel: DepositViewModelType,
         vcFactory: ViewControllerType) {
        self.viewModel = viewModel
        self.vcFactory = vcFactory
        super.init(context: context)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsFeature = PYAnalyticsKeys.FeatureName.deposit
        analyticsScreenName = PYAnalyticsKeys.ScreenName.deposit
        setupViews()
        viewModel.load()
    }

    private func setupViews() {
        navigationItem.set(title: L10n.Deposit.Navigation.deposit)
        // View setup...
    }
}

extension DepositViewController: DepositViewModelDelegate {
    func showError(_ error: EwalletError) {
        showAlert(message: error.localizedDescription)
    }

    func updateLimitInfo(min: Double, max: Double) {
        // Update UI
    }
}
```

**Why this is good:**
- ✓ IBOutlets are `weak`
- ✓ Dependency injection
- ✓ Sets analytics properties
- ✓ Implements delegate pattern
- ✓ No business logic
- ✓ Localized strings

### ❌ BAD Example

```swift
class DepositViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!  // ❌ Not weak

    var viewModel: DepositViewModel?  // ❌ Optional, not injected

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = DepositViewModel()  // ❌ Creating dependency

        // ❌ Business logic in ViewController
        if amount > 1000 {
            // Validation logic...
        }

        // ❌ Hardcoded string
        title = "Deposit"
    }
}
```

## Example 5: DataSource Pattern

### ✅ GOOD Example

```swift
final class CardDataSource: NSObject {
    private var items: [CardModel] = []
    private weak var delegate: CardDataSourceDelegate?

    init(delegate: CardDataSourceDelegate) {
        self.delegate = delegate
    }

    func update(with items: [CardModel]) {
        self.items = items
    }
}

extension CardDataSource: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CardCell.identifier,
            for: indexPath
        ) as! CardCell

        let item = items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

extension CardDataSource: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let item = items[indexPath.row]
        delegate?.didSelectCard(item)
    }
}
```

**Why this is good:**
- ✓ Clean separation from ViewController
- ✓ Weak delegate
- ✓ Proper cell reuse
- ✓ Type-safe cell dequeuing
- ✓ Single responsibility

## Example 6: Error Handling

### ✅ GOOD Example

```swift
enum WithdrawError: Error, LocalizedError {
    case insufficientBalance(available: Double, requested: Double)
    case bankNotAvailable(bankName: String)
    case limitExceeded(limit: Double)
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let available, let requested):
            return L10n.Error.Withdraw.insufficientBalance(
                available.currencyString,
                requested.currencyString
            )
        case .bankNotAvailable(let bankName):
            return L10n.Error.Withdraw.bankNotAvailable(bankName)
        case .limitExceeded(let limit):
            return L10n.Error.Withdraw.limitExceeded(limit.currencyString)
        case .invalidAmount:
            return L10n.Error.Withdraw.invalidAmount
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientBalance:
            return L10n.Error.Withdraw.depositSuggestion
        case .bankNotAvailable:
            return L10n.Error.Withdraw.selectAnotherBank
        default:
            return nil
        }
    }
}
```

**Why this is good:**
- ✓ Typed errors with associated values
- ✓ Implements `LocalizedError`
- ✓ User-friendly error messages
- ✓ Recovery suggestions
- ✓ Uses localized strings

### ❌ BAD Example

```swift
// ❌ Generic error
throw NSError(domain: "WithdrawError", code: 100)

// ❌ String errors
throw "Insufficient balance"

// ❌ Hardcoded messages
let error = NSError(
    domain: "Error",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Failed to withdraw"]
)
```

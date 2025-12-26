# Code Review Examples

Real-world code review examples for the Payoo Merchant iOS app.

## Example 1: ViewModel Review (Critical Issues)

### File: LoginViewModel.swift

```swift
final class LoginViewModel: ViewModelType {
    private let apiService: ApiService
    private let navigator: LoginNavigator

    init(apiService: ApiService, navigator: LoginNavigator) {
        self.apiService = apiService
        self.navigator = navigator
    }

    struct Input {
        let loginTrigger: Driver<(String, String)>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let error: Driver<String>
    }

    func transform(input: Input) -> Output {
        let activityIndicator = ActivityIndicator()

        let result = input.loginTrigger
            .flatMapLatest { username, password in
                return self.apiService.login(username: username, password: password)  // ⚠️ Issue 1
                    .trackActivity(activityIndicator)
            }

        result
            .subscribe(onNext: { response in  // ⚠️ Issue 2
                self.navigator.navigate(to: .home)  // ⚠️ Issue 3
            })

        return Output(
            isLoading: activityIndicator.asDriver(),
            error: result.map { $0.error }.asDriver(onErrorJustReturn: "Unknown error")
        )
    }
}
```

### Review Report

#### ⚠️ Critical Issues

**1. Missing `.catchSessionError()` at line 23**
- **Problem**: API call doesn't handle session errors
- **Impact**: App won't logout on session timeout
- **Fix**:
```swift
return self.apiService.login(username: username, password: password)
    .catchSessionError(self.sessionUC)  // Add this!
    .trackActivity(activityIndicator)
```

**2. Missing `DisposeBag` for subscription at line 27**
- **Problem**: Subscription never disposed, causes memory leak
- **Impact**: ViewModel stays in memory even after deallocation
- **Fix**:
```swift
private let disposeBag = DisposeBag()

result
    .subscribe(onNext: { [weak self] response in
        self?.navigator.navigate(to: .home)
    })
    .disposed(by: disposeBag)  // Add this!
```

**3. Strong self capture at line 28**
- **Problem**: `self` captured strongly in closure
- **Impact**: Retain cycle, memory leak
- **Fix**:
```swift
result
    .subscribe(onNext: { [weak self] response in  // Use [weak self]
        self?.navigator.navigate(to: .home)
    })
    .disposed(by: disposeBag)
```

**4. Missing SessionUseCase dependency**
- **Problem**: Can't use `.catchSessionError()` without SessionUseCase
- **Fix**:
```swift
private let sessionUC: SessionUseCaseType

init(apiService: ApiService, navigator: LoginNavigator, sessionUC: SessionUseCaseType) {
    self.apiService = apiService
    self.navigator = navigator
    self.sessionUC = sessionUC
}
```

#### 📋 Summary
Files: 1 | 🔴 Critical: 4 | 🟡 Warning: 0 | 🔵 Info: 0 | Status: ❌ Must fix before merge

---

## Example 2: UseCase Review (Correct Pattern)

### File: GetProfileUseCase.swift

```swift
public protocol GetProfileUseCaseType {
    func execute() -> Single<Profile>
    func getAndObserve() -> Observable<Profile?>
}

public final class GetProfileUseCase: GetProfileUseCaseType {
    private let apiService: ApiService
    private let localStorage: LocalStorageService
    private let sessionUC: SessionUseCaseType

    public init(apiService: ApiService, localStorage: LocalStorageService, sessionUC: SessionUseCaseType) {
        self.apiService = apiService
        self.localStorage = localStorage
        self.sessionUC = sessionUC
    }

    public func execute() -> Single<Profile> {
        return apiService.getProfile()
            .catchSessionError(sessionUC)  // ✅ Correct!
            .do(onSuccess: { [weak self] profile in
                self?.localStorage.save(profile)
            })
    }

    public func getAndObserve() -> Observable<Profile?> {
        return localStorage.observe(Profile.self)
    }
}
```

### Review Report

#### ✅ Strengths
- **Clean Architecture**: Pure Swift, no UIKit imports
- **Session Error Handling**: Uses `.catchSessionError(sessionUC)` ✓
- **Dependency Injection**: All dependencies injected via constructor ✓
- **Memory Management**: Uses `[weak self]` in closure ✓
- **Single Responsibility**: Each method has one clear purpose ✓
- **Protocol-Oriented**: Defined protocol for abstraction ✓

#### 📋 Summary
Files: 1 | 🔴 Critical: 0 | 🟡 Warning: 0 | 🔵 Info: 0 | Status: ✅ Ready to merge

---

## Example 3: Layer Boundary Violation

### File: Domain/UseCase/ProfileUseCase.swift

```swift
import UIKit  // ⚠️ Issue 1
import Domain
import Data  // ⚠️ Issue 2

public final class ProfileUseCase: ProfileUseCaseType {
    private let repository: ProfileRepositoryImpl  // ⚠️ Issue 3

    public func execute() -> Single<Profile> {
        let indicator = UIActivityIndicatorView()  // ⚠️ Issue 4
        indicator.startAnimating()

        return repository.getProfile()
    }
}
```

### Review Report

#### ⚠️ Critical Issues

**1. UIKit imported in Domain layer at line 1**
- **Problem**: Domain should be pure Swift
- **Impact**: Violates Clean Architecture, ties business logic to UI framework
- **Fix**: Remove `import UIKit`, Domain layer should never import UIKit

**2. Data layer imported in Domain at line 3**
- **Problem**: Dependency arrow points wrong direction
- **Impact**: Violates Clean Architecture, creates circular dependency risk
- **Fix**: Remove `import Data`, only import Domain

**3. Concrete implementation type used at line 6**
- **Problem**: Should depend on protocol, not concrete type
- **Impact**: Tight coupling, can't mock for testing
- **Fix**:
```swift
private let repository: ProfileRepositoryType  // Use protocol
```

**4. UI component in Domain layer at line 9**
- **Problem**: Domain layer creating UI components
- **Impact**: Violates layer separation
- **Fix**: Remove UI logic, use `ActivityIndicator` from RxSwift or handle in ViewModel

#### Corrected Version

```swift
import RxSwift

public final class ProfileUseCase: ProfileUseCaseType {
    private let repository: ProfileRepositoryType  // Protocol, not implementation
    private let sessionUC: SessionUseCaseType

    public init(repository: ProfileRepositoryType, sessionUC: SessionUseCaseType) {
        self.repository = repository
        self.sessionUC = sessionUC
    }

    public func execute() -> Single<Profile> {
        return repository.getProfile()
            .catchSessionError(sessionUC)
    }
}
```

#### 📋 Summary
Files: 1 | 🔴 Critical: 4 | 🟡 Warning: 0 | 🔵 Info: 0 | Status: ❌ Must fix before merge

---

## Example 4: ViewController Review (Good Practices)

### File: TransactionHistoryViewController.swift

```swift
final class TransactionHistoryViewController: BaseViewController {
    // MARK: - Dependencies
    private let viewModel: TransactionHistoryViewModelType
    private let navigator: TransactionHistoryNavigatorType

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateView: UIView!
    private let refreshControl = UIRefreshControl()

    // MARK: - Init
    init(viewModel: TransactionHistoryViewModelType, navigator: TransactionHistoryNavigatorType) {
        self.viewModel = viewModel
        self.navigator = navigator
        super.init(nibName: "TransactionHistoryViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Transaction History"
        tableView.refreshControl = refreshControl
        tableView.register(UINib(nibName: "TransactionCell", bundle: nil),
                          forCellReuseIdentifier: "TransactionCell")
    }

    // MARK: - Binding
    private func bindViewModel() {
        let input = TransactionHistoryViewModel.Input(
            loadTrigger: rx.viewWillAppear.asDriver(),
            refreshTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            selectTrigger: tableView.rx.itemSelected.asDriver()
        )

        let output = viewModel.transform(input: input)

        output.transactions
            .drive(tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        output.isEmpty
            .drive(emptyStateView.rx.isHidden)
            .disposed(by: disposeBag)

        output.isRefreshing
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
    }
}
```

### Review Report

#### ✅ Strengths

**1. Clean MVVM Structure**
- Clear separation: ViewController handles UI, ViewModel handles logic ✓
- No business logic in ViewController ✓
- All logic in bindViewModel() method ✓

**2. Proper Memory Management**
- DisposeBag declared and used ✓
- All subscriptions disposed ✓
- No strong self captures (using Driver which handles it) ✓

**3. Dependency Injection**
- Dependencies injected via constructor ✓
- No direct instantiation ✓
- Protocol types used ✓

**4. Code Organization**
- Proper MARK comments ✓
- Logical method grouping ✓
- Clear naming conventions ✓

**5. RxSwift Best Practices**
- Uses Driver for UI bindings ✓
- Reactive control event handling ✓
- Declarative binding style ✓

#### ℹ️ Minor Suggestions

**1. Consider extracting cell configuration**
```swift
// Current (inline)
.drive(tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { _, item, cell in
    cell.configure(with: item)
}

// Alternative (extracted method)
.drive(tableView.rx.items(cellIdentifier: "TransactionCell", cellType: TransactionCell.self)) { [weak self] _, item, cell in
    self?.configure(cell: cell, with: item)
}

private func configure(cell: TransactionCell, with item: Transaction) {
    cell.configure(with: item)
    // More complex configuration if needed
}
```

**2. Add pull-to-refresh haptic feedback**
```swift
output.isRefreshing
    .filter { !$0 }  // When refresh completes
    .drive(onNext: { _ in
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    })
    .disposed(by: disposeBag)
```

#### 📋 Summary
Files: 1 | 🔴 Critical: 0 | 🟡 Warning: 0 | 🔵 Info: 2 | Status: ✅ Excellent! Ready to merge

---

## Example 5: SwiftLint Violations

### File: OrderSummaryViewModel.swift

```swift
final class OrderSummaryViewModel: ViewModelType {
    func calculateTotal(items: [Item]) -> Double {
        var total: Double = 0
        if items.count > 0 {  // ⚠️ empty_count violation
            for item in items {
                total += item.price
            }
        }
        return total
    }

    func validateCoupon(code: String) -> Bool {
        if 3 == code.count {  // ⚠️ yoda_condition violation
            return true
        }
        return false
    }

    func createView() -> UIView {
        let view = UIView.init()  // ⚠️ explicit_init violation
        return view
    }

    // TODO: fix this later  // ⚠️ todo violation (not tracked)
}
```

### Review Report

#### ⚠️ SwiftLint Violations

**1. empty_count violation at line 4**
- **Rule**: Use `.isEmpty` instead of `.count > 0`
- **Fix**:
```swift
if !items.isEmpty {  // Preferred
    // ...
}
```

**2. yoda_condition violation at line 12**
- **Rule**: Constant should be on right side
- **Fix**:
```swift
if code.count == 3 {  // Correct order
    return true
}
```

**3. explicit_init violation at line 19**
- **Rule**: Remove explicit `.init()` call
- **Fix**:
```swift
let view = UIView()  // Implicit init preferred
```

**4. todo violation at line 23**
- **Rule**: TODO comments should reference a ticket
- **Fix**:
```swift
// TODO: [PAYOO-789] Implement coupon validation with backend
```

#### 📋 SwiftLint Command

Run to check:
```bash
./Pods/SwiftLint/swiftlint lint --path "PayooMerchant/OrderSummaryViewModel.swift"
```

#### 📋 Summary
- **SwiftLint violations**: 4
- **Status**: ⚠️ Fix violations before merge

---

## Example 6: Memory Leak Detection

### File: ImagePickerViewModel.swift

```swift
final class ImagePickerViewModel: ViewModelType {
    private let imageService: ImageService
    private let navigator: Navigator

    func transform(input: Input) -> Output {
        let images = input.selectTrigger
            .flatMapLatest { [weak self] _ -> Observable<[UIImage]> in
                guard let self = self else { return .empty() }
                return self.imageService.fetchImages()
                    .map { urls in
                        return urls.compactMap { url in  // ⚠️ Issue 1
                            let data = try? Data(contentsOf: url)
                            return data.flatMap { UIImage(data: $0) }
                        }
                    }
            }

        input.uploadTrigger
            .withLatestFrom(images)
            .flatMapLatest { images -> Observable<Void> in
                return self.imageService.upload(images: images)  // ⚠️ Issue 2
            }
            .subscribe()  // ⚠️ Issue 3

        return Output(images: images.asDriver(onErrorJustReturn: []))
    }
}
```

### Review Report

#### ⚠️ Critical Issues

**1. Retain cycle in nested closure at line 10**
- **Problem**: Inner closure captures `self` from outer closure
- **Impact**: Memory leak, images stay in memory
- **Detection**: Run Instruments → Leaks tool
- **Fix**:
```swift
return self.imageService.fetchImages()
    .map { [weak self] urls in  // Add [weak self] here too!
        guard let self = self else { return [] }
        return urls.compactMap { url in
            let data = try? Data(contentsOf: url)
            return data.flatMap { UIImage(data: $0) }
        }
    }
```

**2. Strong self capture at line 19**
- **Problem**: `self` captured strongly in closure
- **Fix**:
```swift
.flatMapLatest { [weak self] images -> Observable<Void> in
    guard let self = self else { return .empty() }
    return self.imageService.upload(images: images)
}
```

**3. Subscription never disposed at line 21**
- **Problem**: Memory leak
- **Fix**:
```swift
private let disposeBag = DisposeBag()

input.uploadTrigger
    .withLatestFrom(images)
    .flatMapLatest { [weak self] images -> Observable<Void> in
        guard let self = self else { return .empty() }
        return self.imageService.upload(images: images)
    }
    .subscribe()
    .disposed(by: disposeBag)  // Add this!
```

#### 🛠 Detection Commands

**Find potential memory leaks:**
```bash
# Find closures without [weak self]
grep -r "flatMapLatest\|subscribe" --include="*ViewModel.swift" | grep -v "\[weak self\]"

# Find subscriptions without disposal
grep -r "\.subscribe(" --include="*ViewModel.swift" | grep -v "disposed(by:"
```

**Run Instruments:**
```bash
# Profile for leaks
xcodebuild -workspace PayooMerchant.xcworkspace \
  -scheme "Payoo Merchant Sandbox" \
  -destination 'platform=iOS Simulator,name=iPhone 15,arch=x86_64' \
  | xcpretty

# Then: Xcode → Product → Profile → Leaks
```

#### 📋 Summary
- **Critical issues**: 3 (all memory leaks)
- **Detection tool**: Instruments (Leaks)
- **Status**: ❌ Must fix before merge

---

## Example 7: Complete Feature Review

### Files Reviewed
- `PayooMerchant/Controllers/Withdrawal/WithdrawalViewModel.swift`
- `PayooMerchant/Controllers/Withdrawal/WithdrawalViewController.swift`
- `Domain/UseCase/Withdrawal/WithdrawalUseCase.swift`
- `Data/Service/Remote/WithdrawalService.swift`

### Review Report

#### Architecture ✅
- **Layer Separation**: Correct ✓
- **Dependency Flow**: Presentation → Domain ← Data ✓
- **No violations**: Clean boundaries ✓

#### MVVM Pattern ✅
- **ViewModel**: Implements ViewModelType ✓
- **Input/Output**: Properly defined ✓
- **ViewController**: Only UI bindings ✓

#### RxSwift ✅
- **Memory Management**: All subscriptions disposed ✓
- **Weak Self**: Properly used in closures ✓
- **DisposeBag**: Present in all classes ✓

#### Session Errors ✅
- **API Calls**: All use `.catchSessionError()` ✓
- **SessionUseCase**: Injected everywhere needed ✓

#### Dependency Injection ✅
- **Constructor Injection**: All dependencies injected ✓
- **DependencyContainer**: Properly registered ✓
- **Factory Methods**: Used for VC creation ✓

#### SwiftLint ✅
```bash
$ ./Pods/SwiftLint/swiftlint lint --path "PayooMerchant/Controllers/Withdrawal/"
Linting Swift files in current working directory
Done linting! Found 0 violations, 0 serious in 2 files.
```

#### Tests ✅
- **UseCase Tests**: 5 test cases ✓
- **ViewModel Tests**: 3 test cases ✓
- **Coverage**: 87% ✓

#### 📋 Final Summary
- **Files reviewed**: 4
- **Critical issues**: 0
- **Warnings**: 0
- **SwiftLint violations**: 0
- **Test coverage**: 87%
- **Status**: ✅ Excellent! Approved for merge

---

## Example 8: Naming Convention Violations

### File: PaymentViewModel.swift

```swift
// PaymentViewModel.swift
import Domain
import RxSwift

// ⚠️ Issue 1: Wrong class name pattern
final class PayVM: ViewModelType {
    // ⚠️ Issue 2: Abbreviated variable names
    private let pmtUC: PaymentUseCaseType
    private let navgtr: PaymentNavigatorType
    private let sesUC: SessionUseCaseType

    // ⚠️ Issue 3: Non-descriptive variables
    private let a: Int = 100
    private let b: String = "VND"

    // ⚠️ Issue 4: Wrong constant naming
    private let MAXIMUM_AMOUNT = 50000000

    struct Input {
        let trigger: Driver<Void>
    }

    struct Output {
        let res: Driver<Payment>  // ⚠️ Issue 5: Abbreviated
    }

    func transform(input: Input) -> Output {
        // ⚠️ Issue 6: Single letter variable
        let r = input.trigger
            .flatMapLatest { [weak self] _ -> Observable<Payment> in
                guard let self = self else { return .empty() }
                return self.pmtUC.execute()
            }
        return Output(res: r.asDriver(onErrorJustReturn: nil))
    }
}
```

### Review Report

#### 🟡 Naming Convention Violations

**1. Wrong ViewModel class name** at PaymentViewModel.swift:5
- **Problem**: Class named `PayVM` instead of `PaymentViewModel`
- **Rule**: ViewModels must follow `[Feature]ViewModel` pattern
- **Fix**:
```swift
final class PaymentViewModel: ViewModelType {
```

**2. Abbreviated variable names** at PaymentViewModel.swift:7-9
- **Problem**: Variables use abbreviations (`pmtUC`, `navgtr`, `sesUC`)
- **Rule**: Use full descriptive names, avoid abbreviations
- **Fix**:
```swift
private let paymentUC: PaymentUseCaseType
private let navigator: PaymentNavigatorType
private let sessionUC: SessionUseCaseType
```

**3. Non-descriptive variable names** at PaymentViewModel.swift:12-13
- **Problem**: Variables named `a` and `b`
- **Rule**: Use descriptive names that indicate purpose
- **Fix**:
```swift
private let minimumAmount: Int = 100
private let currency: String = "VND"
```

**4. Wrong constant naming** at PaymentViewModel.swift:16
- **Problem**: All caps constant `MAXIMUM_AMOUNT`
- **Rule**: Use camelCase or `k` prefix for constants
- **Fix**:
```swift
private let maximumAmount = 50_000_000
// or
private let kMaximumAmount = 50_000_000
```

**5. Abbreviated Output property** at PaymentViewModel.swift:23
- **Problem**: Property named `res` instead of `result`
- **Fix**:
```swift
struct Output {
    let result: Driver<Payment>
}
```

**6. Single letter variable** at PaymentViewModel.swift:28
- **Problem**: Variable named `r` instead of descriptive name
- **Rule**: Avoid single letters except in loops
- **Fix**:
```swift
let paymentResult = input.trigger
    .flatMapLatest { [weak self] _ -> Observable<Payment> in
        guard let self = self else { return .empty() }
        return self.paymentUC.execute()
    }

return Output(result: paymentResult.asDriver(onErrorJustReturn: nil))
```

#### Corrected Version

```swift
final class PaymentViewModel: ViewModelType {
    private let paymentUC: PaymentUseCaseType
    private let navigator: PaymentNavigatorType
    private let sessionUC: SessionUseCaseType

    private let minimumAmount: Int = 100
    private let currency: String = "VND"
    private let maximumAmount = 50_000_000

    private let disposeBag = DisposeBag()

    init(
        paymentUC: PaymentUseCaseType,
        navigator: PaymentNavigatorType,
        sessionUC: SessionUseCaseType
    ) {
        self.paymentUC = paymentUC
        self.navigator = navigator
        self.sessionUC = sessionUC
    }

    struct Input {
        let trigger: Driver<Void>
    }

    struct Output {
        let result: Driver<Payment>
    }

    func transform(input: Input) -> Output {
        let paymentResult = input.trigger
            .flatMapLatest { [weak self] _ -> Observable<Payment> in
                guard let self = self else { return .empty() }
                return self.paymentUC.execute()
                    .catchSessionError(self.sessionUC)
            }

        return Output(result: paymentResult.asDriver(onErrorJustReturn: nil))
    }
}
```

#### 📋 Summary
Files: 1 | 🔴 Critical: 0 | 🟡 Warning: 6 | 🔵 Info: 0 | Status: ⚠️ Fix naming violations before merge

#### Naming Convention Quick Reference

**Classes:**
- ✅ `LoginViewModel`, `TransactionHistoryViewModel`
- ✅ `LoginViewController`, `HomeViewController`
- ✅ `GetProfileUseCase`, `LoginUseCase`
- ✅ `LoginNavigator`, `HomeNavigator`
- ❌ `LoginVM`, `TxHistVM`, `GetProfUC`

**Protocols:**
- ✅ `ViewModelType`, `UseCaseType`
- ✅ `LoginViewModelType`, `GetProfileUseCaseType`
- ❌ `LoginVMType`, `GetProfUCType`

**Variables:**
- ✅ `username`, `transactionId`, `isLoading`
- ✅ `paymentItems`, `selectedBankAccount`
- ❌ `usrNm`, `txId`, `a`, `b`, `flag`

**Constants:**
- ✅ `pageSize`, `animationDuration`, `kMaxRetryCount`
- ❌ `PAGE_SIZE`, `ANIMATION_DURATION`

---

## Quick Check Commands

### Find Missing catchSessionError
```bash
grep -r "apiService\." --include="*.swift" PayooMerchant Domain | grep -v "catchSessionError"
```

### Find Files Without DisposeBag
```bash
find PayooMerchant -name "*ViewModel.swift" -exec grep -L "DisposeBag" {} \;
```

### Find Strong Self in Closures
```bash
grep -r "\.subscribe\|\.flatMapLatest\|\.flatMap" --include="*ViewModel.swift" | grep -v "\[weak self\]\|\[unowned self\]"
```

### Run SwiftLint
```bash
./Pods/SwiftLint/swiftlint lint --reporter xcode
```

### Check Layer Imports
```bash
# Check if Domain imports Data (violation)
grep -r "import Data" Domain/

# Check if Domain imports UIKit (violation)
grep -r "import UIKit" Domain/
```

### Find TODOs
```bash
grep -rn "TODO\|FIXME" PayooMerchant Domain Data Analytics
```

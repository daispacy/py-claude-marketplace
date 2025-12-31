# iOS Feature Generator - Complete Examples

Real-world examples of generated features following MVVM + RxSwift Input/Output pattern.

---

## Example 1: Transaction History Feature (Date Range Pagination)

### User Input

```yaml
Feature name: TransactionHistory
Feature path: PayooMerchant/Controllers/Transaction/History
Feature title: Transaction History
Pagination type: date_range
Primary UseCase: TransactionHistoryUseCaseType
Primary method: getTransactions(fromDate:toDate:)
Domain item type: TransactionItem
Main content cell: TransactionCell
Additional inputs: filterByTypeTrigger (Observable<TransactionType?>)
Additional outputs: filterOptions (Driver<[TransactionType]>)
Header cells: TransactionFilterCell
Navigation: transactionDetail(item:), exportTransactions()
```

### Generated Files

#### 1. TransactionHistoryViewModel.swift

```swift
// PayooMerchant/Controllers/Transaction/History/TransactionHistoryViewModel.swift

import Foundation
import RxSwift
import RxCocoa
import Domain

// MARK: - Filter Object
struct TransactionHistoryFilter: FilterPaginationDateRangeProvider {
    var toDate: Date = Date()
    var fromDate: Date = Date().addingTimeInterval(-30 * 24 * 60 * 60)
    var transactionType: TransactionType?
}

// MARK: - ViewModel
final class TransactionHistoryViewModel: BaseListPaginationDateRangeViewModel<TransactionItem, TransactionHistoryFilter, Any> {

    // MARK: - Dependencies
    private let transactionHistoryUC: TransactionHistoryUseCaseType

    // MARK: - Relays
    private let filterOptionsRelay = BehaviorRelay<[TransactionType]>(value: TransactionType.allCases)

    // MARK: - Input
    struct Input {
        let loadTrigger: Observable<Void>
        let loadMoreTrigger: Observable<Void>
        let refreshTrigger: Observable<Void>
        let selectItemTrigger: Observable<IndexPath>
        let changeDateRangeTrigger: Observable<(fromDate: Date, toDate: Date)>
        let filterByTypeTrigger: Observable<TransactionType?>
    }

    // MARK: - Output
    struct Output {
        let items: Driver<[Item]>
        let isLoading: Driver<Bool>
        let shouldLoadMore: Driver<Bool>
        let error: Driver<Error?>
        let selectedItem: Driver<TransactionItem>
        let filterOptions: Driver<[TransactionType]>
    }

    // MARK: - Init
    init(
        transactionHistoryUC: TransactionHistoryUseCaseType,
        navigator: TransactionHistoryNavigatorType
    ) {
        self.transactionHistoryUC = transactionHistoryUC
        super.init(navigator: navigator, filter: TransactionHistoryFilter())
    }

    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        // Handle date range changes
        input.changeDateRangeTrigger
            .subscribe(onNext: { [weak self] dates in
                var newFilter = self?.filterObject.value ?? TransactionHistoryFilter()
                newFilter.fromDate = dates.fromDate
                newFilter.toDate = dates.toDate
                self?.filterObject.accept(newFilter)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // Handle transaction type filter changes
        input.filterByTypeTrigger
            .subscribe(onNext: { [weak self] type in
                var newFilter = self?.filterObject.value ?? TransactionHistoryFilter()
                newFilter.transactionType = type
                self?.filterObject.accept(newFilter)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // Base pagination setup
        let baseOutput = super.transform(
            loadTrigger: input.loadTrigger,
            reloadTrigger: input.refreshTrigger,
            loadMoreTrigger: input.loadMoreTrigger
        )

        // Handle item selection
        let selectedItem = input.selectItemTrigger
            .withLatestFrom(baseOutput.items) { indexPath, items in
                items[indexPath.row]
            }
            .asDriverOnErrorJustComplete()

        return Output(
            items: baseOutput.items,
            isLoading: baseOutput.isLoading,
            shouldLoadMore: baseOutput.shouldLoadMore,
            error: baseOutput.error,
            selectedItem: selectedItem,
            filterOptions: filterOptionsRelay.asDriver()
        )
    }

    // MARK: - Fetch Items
    override func fetchItems(_ toDate: Date) -> Observable<[TransactionItem]> {
        let filter = filterObject.value

        return transactionHistoryUC.getTransactions(
            fromDate: filter.fromDate.toString(format: .defaultFormatDateTime) ?? "",
            toDate: toDate.toString(format: .defaultFormatDateTime) ?? ""
        )
        .asObservable()
        .map { response in
            // Filter by type if selected
            guard let selectedType = filter.transactionType else {
                return response.transactions
            }
            return response.transactions.filter { $0.type == selectedType }
        }
    }
}
```

#### 2. TransactionHistoryController.swift

```swift
// PayooMerchant/Controllers/Transaction/History/TransactionHistoryController.swift

import UIKit
import RxSwift
import RxCocoa
import Domain

final class TransactionHistoryController: BaseViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var filterButton: UIButton!
    @IBOutlet private weak var exportButton: UIBarButtonItem!

    // MARK: - Properties
    var viewModel: TransactionHistoryViewModel!

    // MARK: - Triggers
    private let loadTrigger = PublishSubject<Void>()
    private let loadMoreTrigger = PublishSubject<Void>()
    private let refreshTrigger = PublishSubject<Void>()
    private let selectItemTrigger = PublishSubject<IndexPath>()
    private let changeDateRangeTrigger = PublishSubject<(fromDate: Date, toDate: Date)>()
    private let filterByTypeTrigger = PublishSubject<TransactionType?>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()

        // Initial load
        loadTrigger.onNext(())
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Transaction History"

        // Table view setup
        tableView.do {
            $0.registerCellByNib(TransactionFilterCell.self)
            $0.registerCellByNib(TransactionCell.self)
            $0.registerCellByNib(ErrorOrEmptyStateCell.self)
            $0.estimatedRowHeight = 80
            $0.rowHeight = UITableView.automaticDimension
            $0.separatorStyle = .singleLine
        }

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl

        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: refreshTrigger)
            .disposed(by: disposeBag)

        // Export button
        navigationItem.rightBarButtonItem = exportButton
    }

    // MARK: - Binding
    private func bindViewModel() {
        let input = TransactionHistoryViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: loadMoreTrigger.asObservable(),
            refreshTrigger: refreshTrigger.asObservable(),
            selectItemTrigger: selectItemTrigger.asObservable(),
            changeDateRangeTrigger: changeDateRangeTrigger.asObservable(),
            filterByTypeTrigger: filterByTypeTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        // Bind items to table view
        output.items
            .drive(tableView.rx.items) { [weak self] tableView, index, item in
                guard let self = self else { return UITableViewCell() }

                // Header section (filter)
                if index == 0 {
                    let cell = tableView.dequeueReusableCell(TransactionFilterCell.self, for: IndexPath(row: index, section: 0))
                    cell.configure(
                        filterOptions: try? output.filterOptions.asObservable().take(1).toBlocking().first() ?? [],
                        selectedType: self.viewModel.filterObject.value.transactionType,
                        onSelectType: { [weak self] type in
                            self?.filterByTypeTrigger.onNext(type)
                        }
                    )
                    return cell
                }

                // Transaction items
                let cell = tableView.dequeueReusableCell(TransactionCell.self, for: IndexPath(row: index, section: 0))
                cell.configure(with: item)
                return cell
            }
            .disposed(by: disposeBag)

        // Handle loading state
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if !isLoading {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        // Handle item selection
        output.selectedItem
            .drive(onNext: { [weak self] item in
                self?.navigator.navigate(to: .transactionDetail(item: item))
            })
            .disposed(by: disposeBag)

        // Handle errors
        output.error
            .drive(onNext: { [weak self] error in
                guard let error = error else { return }
                self?.showError(error)
            })
            .disposed(by: disposeBag)

        // Table view selection
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .bind(to: selectItemTrigger)
            .disposed(by: disposeBag)

        // Infinite scroll
        tableView.rx.willDisplayCell
            .filter { [weak self] _, indexPath in
                guard let self = self,
                      let itemsCount = try? output.items.asObservable().take(1).toBlocking().first()?.count
                else { return false }
                return indexPath.row >= itemsCount - 3
            }
            .map { _ in () }
            .bind(to: loadMoreTrigger)
            .disposed(by: disposeBag)

        // Export button
        exportButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigator.navigate(to: .exportTransactions)
            })
            .disposed(by: disposeBag)

        // Filter button
        filterButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.navigator.navigate(to: .dateRangePicker(
                    currentFromDate: self.viewModel.filterObject.value.fromDate,
                    currentToDate: self.viewModel.filterObject.value.toDate,
                    onSelect: { [weak self] fromDate, toDate in
                        self?.changeDateRangeTrigger.onNext((fromDate: fromDate, toDate: toDate))
                    }
                ))
            })
            .disposed(by: disposeBag)
    }
}
```

#### 3. Navigator+TransactionHistory.swift

```swift
// PayooMerchant/Controllers/Transaction/History/Navigator+TransactionHistory.swift

import Foundation
import Domain

// MARK: - Protocol
protocol TransactionHistoryNavigatorType {
    func navigate(to destination: TransactionHistoryDestination)
}

// MARK: - Destinations
enum TransactionHistoryDestination {
    case transactionDetail(item: TransactionItem)
    case dateRangePicker(currentFromDate: Date, currentToDate: Date, onSelect: (Date, Date) -> Void)
    case exportTransactions
}

// MARK: - Navigator Extension
extension Navigator: TransactionHistoryNavigatorType {
    func navigate(to destination: TransactionHistoryDestination) {
        switch destination {
        case .transactionDetail(let item):
            let controller = viewControllerFactory.makeTransactionDetailController(item: item)
            push(controller)

        case .dateRangePicker(let fromDate, let toDate, let onSelect):
            let controller = viewControllerFactory.makeDateRangePickerController(
                fromDate: fromDate,
                toDate: toDate,
                maxDays: 90,
                onSelect: onSelect
            )
            present(controller, animated: true)

        case .exportTransactions:
            let controller = viewControllerFactory.makeExportOptionsController(type: .transactions)
            present(controller, animated: true)
        }
    }
}
```

#### 4. TransactionHistoryViewModelTests.swift

```swift
// PayooMerchantTests/ViewModel/TransactionHistoryViewModelTests.swift

import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import Domain
@testable import PayooMerchant

final class TransactionHistoryViewModelTests: XCTestCase {

    private var viewModel: TransactionHistoryViewModel!
    private var transactionHistoryUC: TransactionHistoryUseCaseMock!
    private var navigator: TransactionHistoryNavigatorMock!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        transactionHistoryUC = TransactionHistoryUseCaseMock()
        navigator = TransactionHistoryNavigatorMock()
        viewModel = TransactionHistoryViewModel(
            transactionHistoryUC: transactionHistoryUC,
            navigator: navigator
        )

        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        viewModel = nil
        transactionHistoryUC = nil
        navigator = nil
        scheduler = nil
        disposeBag = nil

        super.tearDown()
    }

    func test_Transform_LoadTrigger_ReturnsTransactions() {
        // Given
        let mockTransactions = [
            TransactionItem(id: 1, createdDate: "2025-01-01 10:00:00", title: "Payment", amount: 100.0, type: .payment),
            TransactionItem(id: 2, createdDate: "2025-01-01 09:00:00", title: "Refund", amount: 50.0, type: .refund)
        ]

        transactionHistoryUC.getTransactionsReturnValue = .just(TransactionHistoryResponse(transactions: mockTransactions))

        let loadTrigger = scheduler.createHotObservable([.next(10, ())])

        // When
        let input = TransactionHistoryViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: .never(),
            refreshTrigger: .never(),
            selectItemTrigger: .never(),
            changeDateRangeTrigger: .never(),
            filterByTypeTrigger: .never()
        )

        let output = viewModel.transform(input)

        let itemsObserver = scheduler.createObserver([TransactionHistoryViewModel.Item].self)
        output.items.drive(itemsObserver).disposed(by: disposeBag)

        scheduler.start()

        // Then
        XCTAssertTrue(transactionHistoryUC.getTransactionsCalled)
        XCTAssertEqual(itemsObserver.events.last?.value.element?.count, 2)
    }

    func test_Transform_FilterByType_FiltersTransactions() {
        // Given
        let mockTransactions = [
            TransactionItem(id: 1, createdDate: "2025-01-01 10:00:00", title: "Payment", amount: 100.0, type: .payment),
            TransactionItem(id: 2, createdDate: "2025-01-01 09:00:00", title: "Refund", amount: 50.0, type: .refund)
        ]

        transactionHistoryUC.getTransactionsReturnValue = .just(TransactionHistoryResponse(transactions: mockTransactions))

        let loadTrigger = scheduler.createHotObservable([.next(10, ())])
        let filterTrigger = scheduler.createHotObservable([.next(20, TransactionType.payment)])

        // When
        let input = TransactionHistoryViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: .never(),
            refreshTrigger: .never(),
            selectItemTrigger: .never(),
            changeDateRangeTrigger: .never(),
            filterByTypeTrigger: filterTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        let itemsObserver = scheduler.createObserver([TransactionHistoryViewModel.Item].self)
        output.items.drive(itemsObserver).disposed(by: disposeBag)

        scheduler.start()

        // Then
        let filteredItems = itemsObserver.events.last?.value.element
        XCTAssertEqual(filteredItems?.count, 1)
        XCTAssertEqual(filteredItems?.first?.type, .payment)
    }

    func test_MemoryLeak_WeakSelf_DoesNotRetain() {
        // Given
        weak var weakViewModel = viewModel

        // When
        viewModel = nil

        // Then
        XCTAssertNil(weakViewModel)
    }
}

// MARK: - Mocks

final class TransactionHistoryUseCaseMock: TransactionHistoryUseCaseType {
    var getTransactionsCalled = false
    var getTransactionsReturnValue: Single<TransactionHistoryResponse> = .never()

    func getTransactions(fromDate: String, toDate: String) -> Single<TransactionHistoryResponse> {
        getTransactionsCalled = true
        return getTransactionsReturnValue
    }
}

final class TransactionHistoryNavigatorMock: TransactionHistoryNavigatorType {
    var navigateCalled = false
    var navigateDestination: TransactionHistoryDestination?

    func navigate(to destination: TransactionHistoryDestination) {
        navigateCalled = true
        navigateDestination = destination
    }
}
```

---

## Example 2: Simple List Feature (No Pagination)

### User Input

```yaml
Feature name: NotificationList
Feature path: PayooMerchant/Controllers/Notification
Feature title: Notifications
Pagination type: none
Primary UseCase: NotificationUseCaseType
Primary method: getAllNotifications()
Domain item type: NotificationItem
Main content cell: NotificationCell
Navigation: notificationDetail(item:), markAllAsRead()
```

### Generated ViewModel (Simplified)

```swift
// PayooMerchant/Controllers/Notification/NotificationListViewModel.swift

import Foundation
import RxSwift
import RxCocoa
import Domain

final class NotificationListViewModel: BaseViewModel {

    // MARK: - Dependencies
    private let notificationUC: NotificationUseCaseType

    // MARK: - Relays
    private let itemsRelay = BehaviorRelay<[NotificationItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<Error?>(value: nil)

    // MARK: - Input
    struct Input {
        let loadTrigger: Observable<Void>
        let refreshTrigger: Observable<Void>
        let selectItemTrigger: Observable<IndexPath>
        let markAllAsReadTrigger: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let items: Driver<[NotificationItem]>
        let isLoading: Driver<Bool>
        let error: Driver<Error?>
        let selectedItem: Driver<NotificationItem>
    }

    // MARK: - Init
    init(
        notificationUC: NotificationUseCaseType,
        navigator: NotificationListNavigatorType
    ) {
        self.notificationUC = notificationUC
        super.init(navigator: navigator)
    }

    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        let activityIndicator = ActivityIndicator()

        // Load notifications
        let loadedItems = Observable.merge(
            input.loadTrigger,
            input.refreshTrigger
        )
        .flatMapLatest { [weak self] _ -> Observable<[NotificationItem]> in
            guard let self = self else { return .empty() }
            return self.notificationUC.getAllNotifications()
                .asObservable()
                .trackActivity(activityIndicator)
                .do(onError: { [weak self] error in
                    self?.errorRelay.accept(error)
                })
                .catchAndReturn([])
        }
        .bind(to: itemsRelay)

        // Handle selection
        let selectedItem = input.selectItemTrigger
            .withLatestFrom(itemsRelay) { indexPath, items in
                items[indexPath.row]
            }
            .asDriverOnErrorJustComplete()

        // Mark all as read
        input.markAllAsReadTrigger
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.notificationUC.markAllAsRead()
                    .asObservable()
                    .trackActivity(activityIndicator)
            }
            .bind(to: input.loadTrigger) // Reload after marking
            .disposed(by: disposeBag)

        return Output(
            items: itemsRelay.asDriver(),
            isLoading: activityIndicator.asDriver(),
            error: errorRelay.asDriver(),
            selectedItem: selectedItem
        )
    }
}
```

---

## Output Summary Template

```markdown
✅ iOS Feature Generated: TransactionHistory

📁 Files Created:
  - PayooMerchant/Controllers/Transaction/History/TransactionHistoryViewModel.swift (145 lines)
  - PayooMerchant/Controllers/Transaction/History/TransactionHistoryController.swift (182 lines)
  - PayooMerchant/Controllers/Transaction/History/Navigator+TransactionHistory.swift (42 lines)
  - PayooMerchantTests/ViewModel/TransactionHistoryViewModelTests.swift (178 lines)

📋 Manual Steps Required:

1. **Register in DependencyContainer.swift**
   ```swift
   container.register(TransactionHistoryViewModel.self) { resolver in
       TransactionHistoryViewModel(
           transactionHistoryUC: resolver.resolve(TransactionHistoryUseCaseType.self)!,
           navigator: resolver.resolve(TransactionHistoryNavigatorType.self)!
       )
   }
   ```

2. **Add factory method to ViewControllerFactory**
   ```swift
   extension ViewControllerFactory {
       func makeTransactionHistoryController() -> TransactionHistoryController {
           let controller = TransactionHistoryController.instantiate()
           controller.viewModel = DependencyContainer.shared.provide(TransactionHistoryViewModel.self)
           return controller
       }
   }
   ```

3. **Update parent Navigator** (if adding to existing flow)
   Add to home navigator enum:
   ```swift
   case transactionHistory
   ```

🧪 Test the Feature:

1. Build project:
   ```bash
   xcodebuild -workspace PayooMerchant.xcworkspace \
     -scheme "Payoo Merchant Sandbox" \
     -configuration "Debug Sandbox" \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15,arch=x86_64' \
     clean build
   ```

2. Run tests:
   ```bash
   xcodebuild test \
     -workspace PayooMerchant.xcworkspace \
     -scheme "PayooMerchantTests" \
     -configuration "Debug Sandbox" \
     -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15,arch=x86_64' \
     -enableCodeCoverage YES
   ```

3. Navigate: `homeNavigator.navigate(to: .transactionHistory)`

⏱️  Estimated completion time: 15-30 minutes
```

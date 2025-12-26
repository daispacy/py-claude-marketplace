# Real-World Examples

Complete examples from the Payoo Merchant iOS project.

## Example 1: ViewModel with Multiple UseCases

**Source**: `BalanceInformationViewModel.swift`

```swift
final class BalanceInformationViewModelTests: XCTestCase {
    // MARK: - Mocks
    
    private final class MockBalanceInformationUseCase: BalanceInformationUseCaseType {
        var getBalanceInfoResult: Single<BalanceInfoResponse> = .never()
        var getBalanceHistoryResult: Single<BalanceHistoryResponse> = .never()
        var getBalanceInfoCallCount = 0
        var getBalanceHistoryCallCount = 0
        var lastGetBalanceHistoryParams: (fromDate: String, toDate: String, layerId: Int)?

        func getBalanceInfo() -> Single<BalanceInfoResponse> {
            getBalanceInfoCallCount += 1
            return getBalanceInfoResult
        }

        func getBalanceHistory(fromDate: String, toDate: String, layerId: Int) -> Single<BalanceHistoryResponse> {
            getBalanceHistoryCallCount += 1
            lastGetBalanceHistoryParams = (fromDate, toDate, layerId)
            return getBalanceHistoryResult
        }
    }

    private final class MockFeaturesUseCase: FeaturesUseCaseType {
        var executeReturnValue: Observable<[Feature]> = .just([])
        var checkPermissionResult: Bool = true
        var lastCheckedFeature: Feature?

        func execute() -> Observable<[Feature]> {
            executeReturnValue
        }

        func checkPermissionForView(feature: Feature) -> Bool {
            lastCheckedFeature = feature
            return checkPermissionResult
        }
    }

    // MARK: - Properties
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    private var mockBalanceUC: MockBalanceInformationUseCase!
    private var mockFeaturesUC: MockFeaturesUseCase!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        mockBalanceUC = MockBalanceInformationUseCase()
        mockFeaturesUC = MockFeaturesUseCase()
    }

    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        mockBalanceUC = nil
        mockFeaturesUC = nil
        super.tearDown()
    }

    // MARK: - Test Data Factory
    
    private func makeTestBalanceLayerInfo(
        layerId: Int = 1,
        layerName: String = "Main Account",
        balance: Double = 1000000.0,
        description: String = "Main account description"
    ) -> BalanceLayerInfo {
        return BalanceLayerInfo(
            layerId: layerId,
            layerName: layerName,
            balance: balance,
            description: description
        )
    }
    
    private func makeTestBalanceInfoResponse(
        balances: [BalanceLayerInfo]? = nil,
        availableBalance: Double = 1500000.0,
        minimumBalance: Double? = 100000.0
    ) -> BalanceInfoResponse {
        let defaultBalances = [
            makeTestBalanceLayerInfo(layerId: 1, layerName: "Main Account", balance: 1000000.0),
            makeTestBalanceLayerInfo(layerId: 2, layerName: "Savings", balance: 500000.0)
        ]
        return BalanceInfoResponse(
            balances: balances ?? defaultBalances,
            availableBalance: availableBalance,
            minimumBalance: minimumBalance
        )
    }

    private func makeViewModel() -> BalanceInformationViewModel {
        return BalanceInformationViewModel(
            balanceUC: mockBalanceUC,
            featuresUC: mockFeaturesUC
        )
    }

    // MARK: - Tests

    func test_transform_withSuccessfulBalanceInfoLoad_shouldDisplayBalanceData() {
        // Arrange
        let viewModel = makeViewModel()
        let testBalanceInfo = makeTestBalanceInfoResponse()
        
        let loadBalanceInfoTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = BalanceInformationViewModel.Input(
            actionTrigger: .never(),
            loadBalanceInfoTrigger: loadBalanceInfoTrigger.asObservable(),
            loadMoreHistoryTrigger: .never(),
            refreshHistoryTrigger: .never(),
            validateFeatureTrigger: .never(),
            showHUDLoading: .never()
        )

        // Mock successful balance info response
        mockBalanceUC.getBalanceInfoResult = .just(testBalanceInfo)
        mockBalanceUC.getBalanceHistoryResult = .just(BalanceHistoryResponse(histories: []))
        mockFeaturesUC.checkPermissionResult = true

        // Act
        let output = viewModel.transform(input: input)
        let observer = scheduler.createObserver([BalanceInformationViewModel.Item].self)
        
        output.items
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        // Assert
        XCTAssertEqual(observer.events.count, 1)
        let items = observer.events[0].value.element!
        
        let keyValueItems = items.compactMap { item -> (String, String)? in
            if case .keyAndValue(let title, let value) = item {
                return (title, value)
            }
            return nil
        }
        
        XCTAssertEqual(keyValueItems.count, 2)
        XCTAssertEqual(keyValueItems[0].0, L10n.balanceInformationAvailableBalance())
        XCTAssertEqual(keyValueItems[0].1, 1500000.0.currencyString)
        XCTAssertEqual(mockBalanceUC.getBalanceInfoCallCount, 1)
    }

    func test_viewModel_shouldDeallocateProperly() {
        // Arrange
        weak var weakViewModel: BalanceInformationViewModel?
        
        // Act
        autoreleasepool {
            let viewModel = BalanceInformationViewModel(
                balanceUC: mockBalanceUC,
                featuresUC: mockFeaturesUC
            )
            weakViewModel = viewModel
            
            let input = BalanceInformationViewModel.Input(
                actionTrigger: .never(),
                loadBalanceInfoTrigger: .never(),
                loadMoreHistoryTrigger: .never(),
                refreshHistoryTrigger: .never(),
                validateFeatureTrigger: .never(),
                showHUDLoading: .never()
            )
            
            _ = viewModel.transform(input: input)
        }
        
        // Assert
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
}
```

## Example 2: UseCase with Session Error Handling

**Source**: `SessionUseCaseTests.swift`

```swift
class SessionUseCaseTests: XCTestCase {
    // MARK: - Mocks
    
    private final class MockKeyChainService: KeyChainService {
        var getDeviceModelIdentifierReturnValue: String = ""
        var getPasscodeReturnValue: String = ""
        var clearLoginCalled = false
        
        func getDeviceModelIdentifier() -> String {
            return getDeviceModelIdentifierReturnValue
        }
        
        func clearLoginDataWithLastLoginInfo() {
            clearLoginCalled = true
        }
        
        // ... implement all required protocol methods
    }
    
    private final class MockUserDefaultsService: UserDefaultsServiceType {
        var resetCalled = false
        
        func reset() {
            resetCalled = true
        }
    }
    
    // MARK: - Properties
    var useCase: SessionUseCase!
    var mockKeychainService: MockKeyChainService!
    var mockUserDefaultsService: MockUserDefaultsService!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeyChainService()
        mockUserDefaultsService = MockUserDefaultsService()
        AppController.shared.state = .loading
        useCase = SessionUseCase(
            keychainService: mockKeychainService,
            appController: AppController.shared,
            userDefaultsService: mockUserDefaultsService
        )
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        useCase = nil
        mockKeychainService = nil
        mockUserDefaultsService = nil
        disposeBag = nil
        AppController.shared.state = .loading
        super.tearDown()
    }
    
    func testCatchSessionError_SessionTimeoutError_Completable() {
        // Arrange
        AppController.shared.state = .loading
        let sessionUC = useCase!
        let error = SessionTimeoutError()
        let completable = Completable.error(error)
        let expectation = self.expectation(description: "Should call revoke and set state expired")
        var didComplete = false
        var didError: Error?
        
        // Act
        let disposable = AppController.shared.rx.state
            .filter { $0 == .expired }
            .take(1)
            .subscribe(onNext: { _ in
                expectation.fulfill()
            })
        
        completable.catchSessionError(sessionUC)
            .subscribe(onCompleted: {
                didComplete = true
            }, onError: { err in
                didError = err
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        disposable.dispose()
        XCTAssertFalse(didComplete)
        XCTAssertNil(didError)
        XCTAssertEqual(AppController.shared.state, .expired)
    }
    
    func testCatchSessionError_ForceUpdateError_Single() {
        // Arrange
        AppController.shared.state = .loading
        let sessionUC = useCase!
        let error = ForceUpdateError()
        let single = Single<Int>.error(error)
        let expectation = self.expectation(description: "Should call forceUpdate and return never")
        var didEmit = false
        var didError: Error?
        
        // Act
        let disposable = AppController.shared.rx.state
            .filter { $0 == .forceUpdate }
            .take(1)
            .subscribe(onNext: { _ in
                expectation.fulfill()
            })
        
        single.catchSessionError(sessionUC)
            .subscribe(onSuccess: { _ in
                didEmit = true
            }, onError: { err in
                didError = err
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        disposable.dispose()
        XCTAssertFalse(didEmit)
        XCTAssertNil(didError)
        XCTAssertEqual(AppController.shared.state, .forceUpdate)
    }
}
```

## Example 3: ViewModel Without API Calls (Simple Transform)

**Source**: `BalanceHistoryDetailViewModel.swift`

```swift
final class BalanceHistoryDetailViewModelTests: XCTestCase {
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }

    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Test Data Factory
    
    private func makeTestBalanceHistoryItem(
        id: Int = 123,
        createdDate: String = "2025-12-25 10:30:00",
        direction: BalanceDirection = .moneyIn,
        transactionType: BalanceTransactionType = .typeA,
        transactionName: String = "Test Transaction",
        amount: Double = 100000.0,
        balanceAfter: Double = 500000.0,
        sourceName: String = "Test Source"
    ) -> BalanceHistoryItem {
        return BalanceHistoryItem(
            id: id,
            createdDate: createdDate,
            direction: direction,
            transactionType: transactionType,
            transactionName: transactionName,
            amount: amount,
            balanceAfter: balanceAfter,
            sourceName: sourceName
        )
    }
    
    private func makeTestLayer(
        layerId: Int = 1,
        layerName: String = "Test Layer",
        balance: Double = 500000.0,
        description: String = "Test Layer Description"
    ) -> BalanceLayerInfo {
        return BalanceLayerInfo(
            layerId: layerId,
            layerName: layerName,
            balance: balance,
            description: description
        )
    }

    // MARK: - Tests

    func test_transform_withLoadTrigger_shouldReturnCorrectInfoItems() {
        // Arrange
        let testItem = makeTestBalanceHistoryItem()
        let testLayer = makeTestLayer()
        let viewModel = BalanceHistoryDetailViewModel(
            balanceHistoryItem: testItem,
            layer: testLayer
        )

        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])

        let input = BalanceHistoryDetailViewModel.Input(
            loadTrigger: loadTrigger.asObservable()
        )

        // Act
        let output = viewModel.transform(input: input)
        let observer = scheduler.createObserver([InfoModel].self)
        
        output.items
            .drive(observer)
            .disposed(by: disposeBag)

        scheduler.start()

        // Assert
        XCTAssertEqual(observer.events.count, 1)
        
        let items = observer.events[0].value.element!
        XCTAssertEqual(items.count, 7, "Should have 7 info items")
        
        // Verify each item content
        if let keyValueItem = items[0] as? DefaultLayoutInfoModel {
            XCTAssertEqual(keyValueItem.title, L10n.balanceInformationAccountType())
            XCTAssertEqual(keyValueItem.content, "Test Layer")
        } else {
            XCTFail("First item should be DefaultLayoutInfoModel for account type")
        }
    }
}
```

## Key Patterns from Examples

1. **Nested Mocks**: All mocks are `private final class` inside test class
2. **Call Tracking**: `callCount` and `lastParams` for verification
3. **Test Data Factories**: Helper methods with default parameters
4. **Descriptive Assertions**: Messages explain what should happen
5. **Arrange-Act-Assert**: Clear separation in each test
6. **Proper Cleanup**: All properties set to nil in tearDown
7. **TestScheduler**: Hot observables for inputs, observers for outputs

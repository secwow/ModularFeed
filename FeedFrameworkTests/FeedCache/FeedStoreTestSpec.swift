import Foundation

protocol FeedStoreSpecs {
    func test_retrive_deliversEmptyOnEmptyCache()
    func test_retrive_hasNoSideEffectsONEmptyCacheTwice()
    func test_retrive_deliversInsertedValue()
    func test_retrive_deliversFoundValueOnNonEmptyCache()
 
    func test_insert_overridesPreviouslyInsertedDataWithNew()


    func test_delete_hasNoSideEffectOnEmptyCache()
    func test_delete_deletePreviouslyInsertedCache()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveSpecs: FeedStoreSpecs {
    func test_retrive_deliversFailureOnRetrievalError()
    func test_retrive_deliversFailureHasNoSideEffectsOnError()
}

protocol FailableInsertSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
    func test_insert_overridesPreviouslyInsertedDataWithNewDeliversNoError()
}

protocol FailableDeleteSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
}

protocol FailableCompostion: FailableDeleteSpecs, FailableInsertSpecs, FailableRetrieveSpecs {
    
}

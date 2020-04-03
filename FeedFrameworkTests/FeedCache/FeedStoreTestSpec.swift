import Foundation

protocol FeedStoreSpecs {
    func test_retrive_deliversEmptyOnEmptyCache()
    func test_retrive_hasNoSideEffectsOnEmptyCache()
    func test_retrive_deliversFoundValueOnNonEmptyCache()
 
    func test_insert_overridesPreviouslyInsertedCacheValues()

    func test_delete_hasNoSideEffectOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrive_deliversFailureOnRetrievalError()
    func test_retrive_deliversFailureHasNoSideEffectsOnError()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
    func test_insert_overridesPreviouslyInsertedDataWithNewDeliversNoError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_OnEmptyCacheDeliversNoError()
}

protocol FailableCompostion: FailableDeleteFeedStoreSpecs, FailableInsertFeedStoreSpecs, FailableRetrieveFeedStoreSpecs {
    
}

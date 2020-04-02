import XCTest
import FeedFramework

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }

    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)

        expect(sut, toRetrive: .empty, file: file, line: line)
    }
}

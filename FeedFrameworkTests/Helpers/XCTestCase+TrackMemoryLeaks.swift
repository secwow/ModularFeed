import XCTest

extension XCTestCase {
    func trackForMemoryLeak(object: AnyObject,
                                    file:StaticString = #file,
                                    line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated", file: file, line: line)
        }
    }

}


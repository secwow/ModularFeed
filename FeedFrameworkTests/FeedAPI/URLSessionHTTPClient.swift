//
//  URLSessionHTTPClient.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 27.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

class URLHTTPSessionClient {
    let session: URLSession
    
    init(with session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping(HTTPClientResult) -> ()) {
        self.session.dataTask(with: url) { (_, _, error)  in
            if let error = error {
                completion(.failure(error))
                return
            }

        }.resume()
    }
}
// MARK - Helpers
class URLSessionHTTPClient: XCTestCase {
    func test_getFromURL_resumesDataTaskFromURL() {
        let url = URL(string: "http://stub.com")!
        let task = URLSessionDataTaskSpy()
        let session = URLSessionSpy()
        let sut = URLHTTPSessionClient(with: session)
        session.stub(url: url, with: task)
        sut.get(from: url) { _ in}
        XCTAssertEqual(task.resumeCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://stub.com")!
        let sampleError = NSError(domain: "", code: 0)
        let session = URLSessionSpy()
        let sut = URLHTTPSessionClient(with: session)
        session.stub(url: url, error: sampleError)
        let exp = XCTestExpectation(description: "Wait to load")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(error as NSError):
                XCTAssertEqual(sampleError, error)
            default:
                XCTFail()
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

class URLSessionSpy: URLSession {
    var recivedURLs = [URL]()
    private var stubTasks = [URL: Stub]()
    
    private struct Stub {
        let task: URLSessionDataTask
        let error: Error?
    }
    
    func stub(url: URL, with task: URLSessionDataTask = FakeDataTask(), error: Error? = nil) {
        let stub = Stub(task: task, error: error)
        stubTasks[url] = stub
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        if let stub = self.stubTasks[url] {
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
        
        fatalError()
    }
}

class FakeDataTask: URLSessionDataTask {
    override func resume() {}
}

class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCount = 0
    
    override func resume() {
        self.resumeCount += 1
    }
}


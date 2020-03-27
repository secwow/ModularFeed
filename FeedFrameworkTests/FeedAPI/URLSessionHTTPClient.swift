//
//  URLSessionHTTPClient.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 27.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

protocol HTTPSessionTask {
     func resume()
}

class URLHTTPSessionClient {
    let session: HTTPSession
    
    init(with session: HTTPSession) {
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
        let task = HTTPSessionDataTaskSpy()
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

class URLSessionSpy: HTTPSession {
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
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        if let stub = self.stubTasks[url] {
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
        
        fatalError()
    }
}

class FakeDataTask: HTTPSessionTask {
    func resume() {}
}

class HTTPSessionDataTaskSpy: HTTPSessionTask {
    var resumeCount = 0
    
    func resume() {
        self.resumeCount += 1
    }
}


//
//  URLSessionHTTPClient.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 27.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest

class URLHTTPSessionClient {
    let session: URLSession
    
    init(with session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        self.session.dataTask(with: url) { (_, _, _)  in
            
        }.resume()
    }
}
// MARK - Helpers
class URLSessionHTTPClient: XCTestCase {
    func test_getFromURL_createdDataWithTask() {
        let url = URL(string: "http://some-strin.com")!
        let session = URLSessionSpy()
        let sut = URLHTTPSessionClient(with: session)
        sut.get(from: url)
        XCTAssertEqual(session.recivedURLs, [url])
    }
    
    func test_getFromURL_resumesDataTaskFromURL() {
        let url = URL(string: "http://stub.com")!
        let task = URLSessionDataTaskSpy()
        let session = URLSessionSpy()
        let sut = URLHTTPSessionClient(with: session)
        session.stub(url: url, with: task)
        sut.get(from: url)
        XCTAssertEqual(task.resumeCount, 1)
    }
}

class URLSessionSpy: URLSession {
    var recivedURLs = [URL]()
    private var stubTasks = [URL: URLSessionDataTask]()
    
    func stub(url: URL, with task: URLSessionDataTask) {
        stubTasks[url] = task
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.recivedURLs.append(url)
        
        return stubTasks[url] ?? FakeDataTask()
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


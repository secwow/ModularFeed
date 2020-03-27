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
            
        }
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
}

class URLSessionSpy: URLSession {
    var recivedURLs = [URL]()
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.recivedURLs.append(url)
        
        return FakeDataTask()
    }
}

class FakeDataTask: URLSessionDataTask {
    
}

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
    
    init(with session: URLSession = URLSession.shared) {
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
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        URLProtocol.registerClass(URLProtocolStub.self)
        let url = URL(string: "http://stub.com")!
        let sampleError = NSError(domain: "", code: 0)
        let sut = URLHTTPSessionClient()
        URLProtocolStub.stub(url: url, error: sampleError)
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
        URLProtocolStub.stopInterceptingRequests()
    }
}

class URLProtocolStub: URLProtocol {
    static var  recivedURLs = [URL]()
    private static var stubTasks = [URL: Stub]()
    
    private struct Stub {
        let error: Error?
    }
    
    static func stub(url: URL, error: Error? = nil) {
        let stub = Stub(error: error)
        stubTasks[url] = stub
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        
        return stubTasks[url] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stubTasks = [:]
    }
    
    override func startLoading() {
        guard let url = request.url, let stub = URLProtocolStub.stubTasks[url] else {
            return
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
        
    }
    
    override func stopLoading() {}
}



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
    
    func test_getFromURL_performsGetRequestFromURL() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://stub.com")!
        
        let exp = XCTestExpectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { result in }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://stub.com")!
        let sampleError = NSError(domain: "", code: 0)
        
        URLProtocolStub.stub(data: nil, response: nil, error: sampleError)
        let exp = XCTestExpectation(description: "Wait to load")
        
        makeSUT().get(from: url) { result in
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
    
    private func makeSUT(file:StaticString = #file,
    line: UInt = #line) -> URLHTTPSessionClient {
        let sut = URLHTTPSessionClient()
        self.trackForMemoryLeak(object: sut)
        return sut
    }

}

class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var observer: ((URLRequest) -> Void)?
    
    
    private struct Stub {
        let data: Data?
        let error: Error?
        let response: URLResponse?
    }
    
    static func stub( data: Data?, response: URLResponse?, error: Error? = nil) {
        stub = Stub(data: data, error: error, response: response)
    }
    
    static func observeRequest(observer: @escaping (URLRequest) -> Void) {
        self.observer = observer
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        observer?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        observer = nil
    }
    
    override func startLoading() {
        let stub = URLProtocolStub.stub
        if let data = stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
        
    }
    
    override func stopLoading() {}
}



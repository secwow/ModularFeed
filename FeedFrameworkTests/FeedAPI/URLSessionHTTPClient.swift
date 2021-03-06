//
//  URLSessionHTTPClient.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 27.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

// MARK - Helpers
class URLSessionHTTPClient: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.setUp()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGetRequestFromURL() {
        
        let url = anyURL()
        
        let exp = XCTestExpectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { result in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let sampleError = NSError(domain: "", code: 0)
        
        URLProtocolStub.stub(data: nil, response: nil, error: sampleError)
        let recievedError = resultErrorFor(data: nil, response: nil, error: sampleError)
        XCTAssertEqual(recievedError as NSError?, sampleError)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentaionCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_successedWithEmptyDataOnHTTPResponseWithData() {
        let response = anyHTTPURLResponse()
        let emptyData = Data()
        let recivedValues = self.resultValueSuccessCase(data: nil, response: response, error: nil)
        XCTAssertEqual(recivedValues?.data, emptyData)
        XCTAssertEqual(recivedValues?.response?.url, response.url)
        XCTAssertEqual(recivedValues?.response?.statusCode, response.statusCode)
    }
    
    func test_getFromURL_successedOnHTTPResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let recivedValues = self.resultValueSuccessCase(data: data, response: response, error: nil)
        XCTAssertEqual(recivedValues?.data, data)
        XCTAssertEqual(recivedValues?.response?.url, response.url)
        XCTAssertEqual(recivedValues?.response?.statusCode, response.statusCode)
    }
    
    private func anyData() -> Data {
        return Data("some".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 0, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyNonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 10, textEncodingName: nil)
    }
    
    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                file:StaticString = #file,
                                line: UInt = #line) -> Error? {
        let result = self.resultFor(data: data, response: response, error: error)
        
        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure got result instead \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultValueSuccessCase(data: Data?,
                                        response: URLResponse?,
                                        error: Error?,
                                        file:StaticString = #file,
                                        line: UInt = #line) -> (data: Data?, response: HTTPURLResponse?)? {
        let result = self.resultFor(data: data, response: response, error: error)
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected failure got result instead \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?,
                           response: URLResponse?,
                           error: Error?,
                           file:StaticString = #file,
                           line: UInt = #line) -> HTTPClient.Result {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = XCTestExpectation(description: "Wait to load")
        var result:  HTTPClient.Result!
        makeSUT().get(from: anyURL()) { recivedResult in
            result = recivedResult
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return result
    }
    
    private func makeSUT(file:StaticString = #file,
                         line: UInt = #line) -> HTTPClient {
        let sut = URLHTTPSessionClient()
        self.trackForMemoryLeak(object: sut)
        return sut
    }
    
}

class URLProtocolStub: URLProtocol {
    private static var _stub: Stub?

    private static var stub: Stub? {
        get { self.stubQueue.sync {return _stub}}
        set { self.stubQueue.sync { _stub = newValue }}
    }
    
    private static let stubQueue = DispatchQueue(label: "FeedFramework.stubQueue")
    
    private struct Stub {
        let data: Data?
        let error: Error?
        let response: URLResponse?
        let observer: ((URLRequest) -> Void)?
    }
    
    static func stub( data: Data?, response: URLResponse?, error: Error? = nil) {
        stub = Stub(data: data, error: error, response: response, observer: nil)
    }
    
    static func observeRequest(observer: @escaping (URLRequest) -> Void) {
        stub = Stub(data: nil, error: nil, response: nil, observer: observer)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
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
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        stub?.observer?(request)
    }
    
    override func stopLoading() {}
}



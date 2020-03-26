//
//  FeedFrameworkTests.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 25.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_clientDoesNotRequestDataFromURL() {
        let (_, client) = sut()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_clientRequestsDataFromURL() {
        let url = URL(string: "http://some-url.com")!
        let (loader, client) = sut(url: url)
        loader.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_clientRequestsDataFromURL() {
        let url = URL(string: "http://some-url.com")!
        let (loader, client) = sut(url: url)
        loader.load{ _ in }
        loader.load{ _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClient() {
        let (loader, client) = sut()
        
        expect(loader, toCompleteWithError: .connectivity, when: {
              let error = NSError(domain: "", code: 0)
              client.complete(with: error)
        })
    }
    
    func test_load_deliversErrorOnNon200CodeHTTPResponse() {
        let (loader, client) = sut()
        
        
        [199, 200, 201, 300, 400, 500].enumerated().forEach { (index, code) in
            expect(loader, toCompleteWithError: .invalidData, when: {
               client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HttpResponeWithInvalidJSON() {
        let (loader, client) = sut()
        
        expect(loader, toCompleteWithError: .invalidData, when: {
           let invalidJSON = Data("Data".utf8)
           client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithError error: RemoteFeedLoader.Error,
                        when: (() -> Void) = {},
                        file: StaticString = #file,
                        line: UInt = #line) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        when()
        
        XCTAssertEqual(capturedErrors, [error], file: file, line: line)
    }
    
    private func sut(url: URL =  URL(string: "http://some-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(requestedURL: url, httpClient: client)
        return (loader, client)
    }
}

class HTTPClientSpy: HTTPClient {
    
    private var messages: [(url: URL, completion: ((HTTPClientResult) -> ()))] = []
    var requestedURLs: [URL] {
        return messages.map{$0.url}
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> ()) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(url: message.url, statusCode: code, httpVersion: nil, headerFields: nil)!
        message.completion(.success(data, response))
    }
}

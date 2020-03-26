//
//  FeedFrameworkTests.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 25.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

class HTTPClientSpy: HTTPClient {
    
    private var messages: [(url: URL, completion: ((Error?, HTTPURLResponse?) -> ()))] = []
    var requestedURLs: [URL] {
        return messages.map{$0.url}
    }
    
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> ()) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(error, nil)
    }
    
    func comlete(withStatusCode code: Int, at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(url: message.url, statusCode: code, httpVersion: nil, headerFields: nil)
        message.completion(nil, response)
    }
}

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
        
        var capturedErrors = [RemoteFeedLoader.Error?]()
        
        loader.load() {
            capturedErrors.append($0)
        }
        let error = NSError(domain: "", code: 0)
        
        client.complete(with: error)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200CodeHTTPResponse() {
           let (loader, client) = sut()
           
           var capturedErrors = [RemoteFeedLoader.Error?]()
           
           loader.load() {
               capturedErrors.append($0)
           }
           
           client.comlete(withStatusCode: 400)
           
           XCTAssertEqual(capturedErrors, [.invalidData])
       }
    
    func sut(url: URL =  URL(string: "http://some-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(requestedURL: url, httpClient: client)
        return (loader, client)
    }
}

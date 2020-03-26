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
    
    var requestedURLs: [URL] = []
    
    var error: Error?
    var requestCount: Int = 0
    
    func get(from url: URL, completion: (Error?) -> ()) {
        requestedURLs.append(url)
        completion(error)
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
        loader.load()
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_clientRequestsDataFromURL() {
        let url = URL(string: "http://some-url.com")!
        let (loader, client) = sut(url: url)
        loader.load()
        loader.load()
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClient() {
        let (loader, client) = sut()
        client.error = NSError(domain: "", code: 405)
        var capturedError: RemoteFeedLoader.Error?
        loader.load() { error in
           capturedError = error
        }
        
        XCTAssertEqual(capturedError, .connectivity)
    }
    
    func sut(url: URL =  URL(string: "http://some-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(requestedURL: url, httpClient: client)
        return (loader, client)
    }
}

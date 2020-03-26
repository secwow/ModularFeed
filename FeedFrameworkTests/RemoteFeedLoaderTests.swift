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
    var requestedURL: URL?
    
    func get(from url: URL) {
        self.requestedURL = url
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func init_clientDoesNotRequestURL() {
           let (_, client) = sut()
           XCTAssertNil(client.requestedURL)
       }
    
    func init_clientRequestsURL() {
        let url = URL(string: "http://some-url.com")!
        let (loader, client) = sut(url: url)
        loader.load()
        XCTAssertEqual(client.requestedURL, url)
    }
    
    func sut(url: URL =  URL(string: "http://some-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(requestedURL: url, httpClient: client)
        return (loader, client)
    }
}

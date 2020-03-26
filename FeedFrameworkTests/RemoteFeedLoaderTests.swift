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
        
        expect(loader, toCompleteWithResult: .failure(.connectivity), when: {
            let error = NSError(domain: "", code: 0)
            client.complete(with: error)
        })
    }
    
    func test_load_deliversErrorOnNon200CodeHTTPResponse() {
        let (loader, client) = sut()
        
        
        [199, 200, 201, 300, 400, 500].enumerated().forEach { (index, code) in
            expect(loader, toCompleteWithResult: .failure(.invalidData), when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HttpResponeWithInvalidJSON() {
        let (loader, client) = sut()
        
        expect(loader, toCompleteWithResult: .failure(.invalidData), when: {
            let invalidJSON = Data("Data".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200ResponseWithEmptyJSONList() {
        let (loader, client) = sut()
        expect(loader, toCompleteWithResult: .success([]), when: {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200ResponseWithValidJSON() {
        let (loader, client) = sut()
        let feedItem = FeedItem(id: UUID(),
                                description: nil,
                                location: nil,
                                imageURL: URL(string: "http://image.url")!)
        let feedItemJSON = [
            "id": feedItem.id.uuidString,
            "image": feedItem.imageURL.absoluteString
        ]
        let feedItem2 = FeedItem(id: UUID(),
                                 description: "desc",
                                 location: "descip",
                                 imageURL: URL(string: "http://image-fd.url")!)
        
        let feedItemJSON2 = [
            "id": feedItem2.id.uuidString,
            "description": feedItem2.description,
            "location" : feedItem2.location,
            "image": feedItem2.imageURL.absoluteString
        ]
        
        let itemsJSON = ["items": [feedItemJSON, feedItemJSON2]]
        
        expect(loader, toCompleteWithResult: .success([feedItem, feedItem2]), when: {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult result: RemoteFeedLoader.Result,
                        when: (() -> Void) = {},
                        file: StaticString = #file,
                        line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        when()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
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

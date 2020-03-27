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
    var leakDetector: RemoteFeedLoader?
    
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
        loader.load { _ in }
        loader.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClient() {
        let (loader, client) = sut()
        
        expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.connectivity), when: {
            let error = NSError(domain: "", code: 0)
            client.complete(with: error)
        })
    }
    
    func test_load_deliversErrorOnNon200CodeHTTPResponse() {
        let (loader, client) = sut()
        
        
        [199, 201, 300, 400, 500].enumerated().forEach { (index, code) in
            expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HttpResponeWithInvalidJSON() {
        let (loader, client) = sut()
        
        expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData), when: {
            let invalidJSON = Data("Data".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200ResponseWithEmptyJSONList() {
        let (loader, client) = sut()
        expect(loader, toCompleteWithResult: .success([]), when: {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200ResponseWithValidJSON() {
        let (loader, client) = sut()
        let item1 = makeItem(id: UUID(),
                             description: nil,
                             location: nil,
                             imageURL: URL(string: "http://image.url")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "desc",
                             location: "descip",
                             imageURL: URL(string: "http://image-fd.url")!)
        
        
        expect(loader, toCompleteWithResult: .success([item1.model, item2.model]), when: {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    func test_load_doesntDeliverResultAfterSUTWasDeallocated() {
        let url = URL(string: "http://image.url")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(requestedURL: url, httpClient: client)
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]){
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let feedItemJSON = [
            "id": item.id.uuidString,
            "description": item.description,
            "location" : item.location,
            "image": item.imageURL.absoluteString
            ].reduce(into: [String: Any](), {acc, e in
                if let value = e.value {
                    acc[e.key] = value
                }
            })
        return (item, feedItemJSON)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": items])
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult expectedResult: RemoteFeedLoader.Result,
                        when: (() -> Void) = {},
                        file: StaticString = #file,
                        line: UInt = #line) {

        let expectation = XCTestExpectation(description: "Waiting for load")
        
        sut.load { recievedResult in
            switch (recievedResult, expectedResult) {
                
            case let (.success(recivedItems), .success(expectedItems)):
                XCTAssertEqual(recivedItems, expectedItems, file: file, line: line)
            case let (.failure(recievedError), .failure(expectedError)):
                XCTAssertEqual(recievedError, expectedError, file: file, line: line)
            default:
                XCTFail("Failed assertion expected \(expectedResult) but recieved \(recievedResult) instead")
            }
            
            expectation.fulfill()
        }
        
        when()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func sut(url: URL =  URL(string: "http://some-url.com")!,
                     file: StaticString = #file,
                     line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(requestedURL: url, httpClient: client)
        trackForMemoryLead(object: client)
        trackForMemoryLead(object: loader)
        
        
        return (loader, client)
    }
    
    private func trackForMemoryLead(object: AnyObject,
                                    file:StaticString = #file,
                                    line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated", file: file, line: line)
        }
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
    
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let message = messages[index]
        let response = HTTPURLResponse(url: message.url, statusCode: code, httpVersion: nil, headerFields: nil)!
        message.completion(.success(data, response))
    }
}

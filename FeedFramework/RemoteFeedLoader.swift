//
//  RemoteFeedLoader.swift
//  FeedFramework
//
//  Created by AndAdmin on 26.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> ())
}

public final class RemoteFeedLoader {
    private let requestedURL: URL
    private let httpClient: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity, invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(requestedURL: URL, httpClient: HTTPClient) {
        self.requestedURL = requestedURL
        self.httpClient = httpClient
    }
    
    public func load(completion: @escaping (Result) -> ()) {
        self.httpClient.get(from: requestedURL) { result in
            switch result {
            case let .success(data, response):
                if response.statusCode == 200, let jsonData = try? JSONDecoder().decode(FeedItems.self, from: data) {
                    completion(.success(jsonData.items.map({$0.item})))
                    return
                }
                completion(.failure(.invalidData))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct FeedItems: Decodable {
    let items: [Item]
}

private struct Item: Decodable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let image: URL
    
    var item: FeedItem {
        return FeedItem(id: id, description: description, location: location, imageURL: image)
    }
}

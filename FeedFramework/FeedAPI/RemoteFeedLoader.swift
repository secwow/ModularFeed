//
//  RemoteFeedLoader.swift
//  FeedFramework
//
//  Created by AndAdmin on 26.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let requestedURL: URL
    private let httpClient: HTTPClient
    
    public typealias Result = LoadFeedResult
    
    public enum Error: Swift.Error {
        case connectivity, invalidData
    }
    
    public init(requestedURL: URL, httpClient: HTTPClient) {
        self.requestedURL = requestedURL
        self.httpClient = httpClient
    }
    
    public func load(completion: @escaping (Result) -> ()) {

        self.httpClient.get(from: requestedURL) {[weak self] result in
            guard self != nil else {
                return
            }
            
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items.toModels()))
                } catch {
                    completion(.failure(RemoteFeedLoader.Error.invalidData))
                }
               
            case .failure(_):
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return self.map({FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image)})
    }
}

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
                completion(FeedItemsMapper.map(data, response))
            case .failure(_):
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
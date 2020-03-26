//
//  RemoteFeedLoader.swift
//  FeedFramework
//
//  Created by AndAdmin on 26.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader {
    private let requestedURL: URL
    private let httpClient: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity, invalidData
    }
    
    public init(requestedURL: URL, httpClient: HTTPClient) {
        self.requestedURL = requestedURL
        self.httpClient = httpClient
    }
    
    public func load(completion: @escaping (Error?) -> ()) {
        self.httpClient.get(from: requestedURL) { error, response in
            if response != nil {
                completion(.invalidData)
            } else {
                completion(.connectivity)
            }
            
        }
    }
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> ())
}

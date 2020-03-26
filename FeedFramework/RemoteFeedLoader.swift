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
    
    public init(requestedURL: URL, httpClient: HTTPClient) {
        self.requestedURL = requestedURL
        self.httpClient = httpClient
    }
    
    public func load() {
        self.httpClient.get(from: requestedURL)
    }
}

public protocol HTTPClient {
    func get(from url: URL)
}

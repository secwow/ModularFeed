import Foundation

public class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map({$0.local})
        }
    }
    
    public struct CodableFeedImage: Codable  {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    public init(with storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp ))
        } catch {
            completion(.failure(error: error))
        }
        
    }
    
    public func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feedItems.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        do {
            try encoded.write(to: storeURL)
            completion(nil)
        } catch  {
            completion(error)
        }
    }
    
    public func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        guard FileManager.default.fileExists(atPath: self.storeURL.path) else {
            completion(nil)
            return
        }
        
        do {
            try FileManager.default.removeItem(at: self.storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

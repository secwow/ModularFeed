import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}

class FeedItemsMapper {
    private struct FeedItems: Decodable {
        let items: [RemoteFeedItem]
    }
    
    static var OK_200: Int { return 200 }

    private struct Item: Decodable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == FeedItemsMapper.OK_200, let feedItems = try? JSONDecoder().decode(FeedItems.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return feedItems.items
    }
}


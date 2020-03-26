import Foundation

class FeedItemsMapper {
    private struct FeedItems: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            return items.map({$0.item})
        }
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
    
    static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == FeedItemsMapper.OK_200, let feedItems = try? JSONDecoder().decode(FeedItems.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }

        return .success(feedItems.feed)
    }
}


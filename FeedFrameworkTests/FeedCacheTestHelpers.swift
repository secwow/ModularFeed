import FeedFramework
import Foundation

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "fds", location: "fds", url: URL(string: "http://some.url")!)
}


func uniqueImageFeed() -> (models: [FeedImage], localRepresentation: [LocalFeedImage]) {
    let items: [FeedImage] = [uniqueImage(), uniqueImage()]
    let localItems = items.map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    return (items, localItems)
}

func anyURL() -> URL {
    return URL(string: "http://image.url")!
}
func anyNSError() -> NSError {
    return NSError(domain: "", code: 0, userInfo: nil)
}


extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .second, value: seconds, to: self)!
    }
}

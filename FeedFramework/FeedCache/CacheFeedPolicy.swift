import Foundation

final class FeedCachePolicy {
    private init () {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    static func validate(timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheDate
    }
}

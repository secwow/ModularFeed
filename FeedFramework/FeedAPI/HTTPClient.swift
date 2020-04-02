import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    /// Completion can be called at any Thread
      /// Client are responsible for dispatch it on correct thread
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> ())
}

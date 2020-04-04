import Foundation



public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    /// Completion can be called at any Thread
      /// Client are responsible for dispatch it on correct thread
    func get(from url: URL, completion: @escaping (Result) -> ())
}

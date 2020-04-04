import Foundation

public class URLHTTPSessionClient: HTTPClient {
    let session: URLSession
    
    public init(with session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentedError: Error {}
    
    public func get(from url: URL, completion: @escaping(HTTPClient.Result) -> ()) {
        self.session.dataTask(with: url) { (data, response, error)  in
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw UnexpectedValuesRepresentedError()
                }
            })
        }.resume()
    }
}

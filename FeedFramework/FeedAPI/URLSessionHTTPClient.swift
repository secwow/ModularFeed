import Foundation

public class URLHTTPSessionClient: HTTPClient {
    let session: URLSession
    
    public init(with session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentedError: Error {}
    
    public func get(from url: URL, completion: @escaping(HTTPClient.Result) -> ()) {
        self.session.dataTask(with: url) { (data, response, error)  in
            if let error = error {
                completion(.failure(error))
                return
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentedError()))
            }
            
        }.resume()
    }
}

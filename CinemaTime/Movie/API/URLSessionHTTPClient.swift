//  Created by Marcell Magyar on 05.12.22.

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public typealias Result = HTTPClient.Result
    
    public init(session: URLSession) {
        self.session = session
    }
    
    private struct UnknownCaseRepresentation: Swift.Error {}
    
    public func get(from url: URL, completion: @escaping (Result) -> Void) {
        let urlRequest = URLRequest(url: url)
        
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnknownCaseRepresentation()))
            }
        }.resume()
    }
}

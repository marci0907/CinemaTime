//  Created by Marcell Magyar on 05.12.22.

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public typealias Result = HTTPClient.Result
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    private struct UnknownCaseRepresentation: Swift.Error {}
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnknownCaseRepresentation()))
            }
        }
        
        task.resume()
        
        return URLSessionTaskWrapper(wrapped: task)
    }
}

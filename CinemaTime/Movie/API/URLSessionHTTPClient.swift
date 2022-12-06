//  Created by Marcell Magyar on 05.12.22.

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let apiKey: String
    
    public typealias Result = HTTPClient.Result
    
    public init(session: URLSession, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
    }
    
    private struct UnknownCaseRepresentation: Swift.Error {}
    
    public func get(from url: URL, completion: @escaping (Result) -> Void) {
//        var urlComponents = URLComponents(string: url.absoluteString)!
//        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
//
//        let urlRequest = URLRequest(url: urlComponents.url!)
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

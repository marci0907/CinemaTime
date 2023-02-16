//  Created by Marcell Magyar on 06.12.22.

import Foundation

public final class AuthenticatedHTTPClientDecorator: HTTPClient {
    private let decoratee: HTTPClient
    private let apiKey: String
    
    public init(decoratee: HTTPClient, apiKey: String) {
        self.decoratee = decoratee
        self.apiKey = apiKey
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let signedURL = signedURL(from: url)
        
        return decoratee.get(from: signedURL, completion: completion)
    }
    
    private func signedURL(from url: URL) -> URL {
        var urlComponents = URLComponents(string: url.absoluteString)!
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [URLQueryItem(name: "api_key", value: apiKey)]
        
        return urlComponents.url!
    }
}

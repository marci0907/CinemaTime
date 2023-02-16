//  Created by Marcell Magyar on 02.12.22.

import Foundation

public final class RemoteMovieLoader: MovieLoader {
    private let url: URL
    private let client: HTTPClient
    
    typealias Result = MovieLoader.Result
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (MovieLoader.Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                completion(RemoteMovieLoader.map(data, response: response))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private static func map(_ data: Data, response: HTTPURLResponse) -> Result {
        do {
            return .success(try RemoteMovieMapper.map(data, response: response))
        } catch {
            return .failure(error)
        }
    }
}

//  Created by Marcell Magyar on 12.12.22.

import Foundation

public final class RemoteMovieImageDataLoader: MovieImageDataLoader {
    private let baseURL: URL
    private let client: HTTPClient
    
    public typealias Result = MovieImageDataLoader.Result
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    private class HTTPClientTaskWrapper: MovieImageDataLoaderTask {
        var completion: ((HTTPClient.Result) -> Void)?
        
        var wrapped: HTTPClientTask?
        
        init(_ completion: @escaping (HTTPClient.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: HTTPClient.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
            wrapped?.cancel()
        }
    }
    
    public init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }
    
    public func load(from imagePath: String, completion: @escaping (Result) -> Void) -> MovieImageDataLoaderTask {
        let task = HTTPClientTaskWrapper { result in
            switch result {
            case let .success((data, response)):
                completion(RemoteMovieImageDataMapper.map(data, response: response))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
        
        let fullImageURL = baseURL.appendingPathComponent(imagePath)
        task.wrapped = client.get(from: fullImageURL) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result)
        }
        
        return task
    }
}

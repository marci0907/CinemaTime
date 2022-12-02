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
    
    private struct Root: Decodable {
        let results: [RemoteMovie]
    }
    
    private static func map(_ data: Data, response: HTTPURLResponse) -> Result {
        do {
            let remoteMovies = try RemoteMovieMapper.map(data, response: response)
            return .success(remoteMovies.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteMovie {
    func toModels() -> [Movie] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return compactMap { remoteMovie -> Movie? in
            guard let id = remoteMovie.id, let title = remoteMovie.title else { return nil }
            
            return Movie(
                id: id,
                title: title,
                imagePath: remoteMovie.posterPath,
                overview: remoteMovie.overview,
                releaseDate: dateFormatter.date(from: remoteMovie.releaseDate),
                rating: remoteMovie.voteAverage
            )
        }
    }
}

private extension DateFormatter {
    func date(from string: String?) -> Date? {
        guard let string = string else {
            return nil
        }
        return date(from: string)
    }
}

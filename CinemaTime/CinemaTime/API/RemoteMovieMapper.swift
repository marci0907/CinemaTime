//  Created by Marcell Magyar on 02.12.22.

import Foundation

final class RemoteMovieMapper {
    private struct Root: Decodable {
        private let results: [RemoteMovie]
        
        private struct RemoteMovie: Decodable {
            let id: Int?
            let title: String?
            let posterPath: String?
            let overview: String?
            let releaseDate: Date?
            let voteAverage: Double?
            
            enum CodingKeys: String, CodingKey {
                case id
                case title
                case posterPath = "poster_path"
                case overview
                case releaseDate = "release_date"
                case voteAverage = "vote_average"
            }
        }
        
        var movies: [Movie] {
            results.compactMap { remoteMovie -> Movie? in
                guard let id = remoteMovie.id, let title = remoteMovie.title else { return nil }
                
                return Movie(
                    id: id,
                    title: title,
                    imagePath: remoteMovie.posterPath,
                    overview: remoteMovie.overview,
                    releaseDate: remoteMovie.releaseDate,
                    rating: remoteMovie.voteAverage
                )
            }
        }
    }
    
    static func map(_ data: Data, response: HTTPURLResponse) throws -> [Movie] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .movieDB
        
        guard response.statusCode == 200, let root = try? decoder.decode(Root.self, from: data) else {
            throw RemoteMovieLoader.Error.invalidData
        }
        
        return root.movies
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static var movieDB: JSONDecoder.DateDecodingStrategy {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        return formatted(dateFormatter)
    }
}

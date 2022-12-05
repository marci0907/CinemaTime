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
            let releaseDate: String?
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            return results.compactMap { remoteMovie -> Movie? in
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
    
    static func map(_ data: Data, response: HTTPURLResponse) throws -> [Movie] {
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteMovieLoader.Error.invalidData
        }
        
        return root.movies
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

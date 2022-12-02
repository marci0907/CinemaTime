//  Created by Marcell Magyar on 02.12.22.

import Foundation

final class RemoteMovieMapper {
    private struct Root: Decodable {
        let results: [RemoteMovie]
    }
    
    static func map(_ data: Data, response: HTTPURLResponse) throws -> [RemoteMovie] {
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteMovieLoader.Error.invalidData
        }
        
        return root.results
    }
}

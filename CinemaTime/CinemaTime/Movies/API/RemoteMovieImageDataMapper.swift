//  Created by Marcell Magyar on 12.12.22.

import Foundation

class RemoteMovieImageDataMapper {
    private init() {}
    
    static func map(_ data: Data, response: HTTPURLResponse) -> RemoteMovieImageDataLoader.Result {
        guard response.statusCode == 200, !data.isEmpty else {
            return .failure(RemoteMovieImageDataLoader.Error.invalidData)
        }
        
        return .success(data)
    }
}

//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class CinemaTimeAPIEndToEndTests: XCTestCase {
    
    func test_load_deliversInvalidDataErrorWithoutAPIKey() {
        let config = URLSessionConfiguration.ephemeral
        let client = URLSessionHTTPClient(session: URLSession(configuration: config), apiKey: "")
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing")!
        let remoteLoader = RemoteMovieLoader(url: url, client: client)
        
        let exp = expectation(description: "Wait for request completion")
        remoteLoader.load { result in
            switch result {
            case let .failure(error as RemoteMovieLoader.Error):
                XCTAssertEqual(error, RemoteMovieLoader.Error.invalidData)
                
            default:
                XCTFail("Expected invalidData error, received \(result)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
    }
    
    func test_load_deliversNowPlayingMoviesWithValidAPIKey() {
        let config = URLSessionConfiguration.ephemeral
        let client = URLSessionHTTPClient(session: URLSession(configuration: config), apiKey: APIKey)
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing")!
        let remoteLoader = RemoteMovieLoader(url: url, client: client)
        
        let exp = expectation(description: "Wait for request completion")
        remoteLoader.load { result in
            switch result {
            case let .success(movies):
                XCTAssertEqual(movies.count, 20)
                
            default:
                XCTFail("Expected success, received \(result)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
    }
}

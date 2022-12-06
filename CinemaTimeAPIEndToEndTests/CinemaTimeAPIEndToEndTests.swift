//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class CinemaTimeAPIEndToEndTests: XCTestCase {
    
    func test_load_deliversInvalidDataErrorWithInvalidAPIKey() {
        let config = URLSessionConfiguration.ephemeral
        let client = URLSessionHTTPClient(session: URLSession(configuration: config), apiKey: "invalid api key")
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
        switch nowPlayingMoviesResult() {
        case let .success(movies):
            XCTAssertEqual(movies.count, 20)
            
        case let .failure(error):
            XCTFail("Expected success, received \(error) instead")
            
        default:
            XCTFail("Expected success, received no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func nowPlayingMoviesResult(file: StaticString = #file, line: UInt = #line) -> Result<[Movie], Error>? {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral), apiKey: APIKey)
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing")!
        let remoteLoader = RemoteMovieLoader(url: url, client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(remoteLoader, file: file, line: line)
        
        let exp = expectation(description: "Wait for request completion")
        var result: Result<[Movie], Error>?
        remoteLoader.load { receivedResult in
            result = receivedResult
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        
        return result
    }
}

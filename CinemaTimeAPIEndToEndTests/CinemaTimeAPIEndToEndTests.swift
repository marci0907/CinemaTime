//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class CinemaTimeAPIEndToEndTests: XCTestCase {
    
    func test_load_deliversInvalidDataErrorWithInvalidAPIKey() {
        switch nowPlayingMoviesResult(with: "") {
        case let .failure(error as RemoteMovieLoader.Error):
            XCTAssertEqual(error, RemoteMovieLoader.Error.invalidData)
            
        case let .success(movies):
            XCTFail("Expected failure, received success with \(movies) instead")
            
        default:
            XCTFail("Expected success, received no result instead")
        }
    }
    
    func test_load_deliversNowPlayingMoviesWithValidAPIKey() {
        switch nowPlayingMoviesResult(with: APIKey) {
        case let .success(movies):
            XCTAssertEqual(movies.count, 20)
            
        case let .failure(error):
            XCTFail("Expected success, received \(error) instead")
            
        default:
            XCTFail("Expected success, received no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func nowPlayingMoviesResult(with apiKey: String, file: StaticString = #file, line: UInt = #line) -> Result<[Movie], Error>? {
        let remoteLoader = RemoteMovieLoader(
            url: URL(string: "https://api.themoviedb.org/3/movie/now_playing")!,
            client: client(with: apiKey))
        
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
    
    private func client(with apiKey: String, file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let authenticatedClient = AuthenticatedHTTPClientDecorator(decoratee: client, apiKey: apiKey)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(authenticatedClient, file: file, line: line)
        return authenticatedClient
    }
}

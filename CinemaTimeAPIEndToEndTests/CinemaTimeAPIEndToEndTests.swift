//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class CinemaTimeAPIEndToEndTests: XCTestCase {
    
    func test_load_deliversInvalidDataErrorWithInvalidAPIKey() {
        switch nowPlayingMoviesResult(with: .notAuthenticated) {
        case let .failure(error as RemoteMovieLoader.Error):
            XCTAssertEqual(error, RemoteMovieLoader.Error.invalidData)
            
        case let .success(movies):
            XCTFail("Expected failure, received success with \(movies) instead")
            
        default:
            XCTFail("Expected success, received no result instead")
        }
    }
    
    func test_load_deliversNowPlayingMoviesWithValidAPIKey() {
        switch nowPlayingMoviesResult(with: .authenticated) {
        case let .success(movies):
            XCTAssertEqual(movies.count, 20)
            
        case let .failure(error):
            XCTFail("Expected success, received \(error) instead")
            
        default:
            XCTFail("Expected success, received no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func nowPlayingMoviesResult(with clientType: ClientType, file: StaticString = #file, line: UInt = #line) -> Result<[Movie], Error>? {
        let client = client(forType: clientType)
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing")!
        let remoteLoader = RemoteMovieLoader(url: url, client: client)
        
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
    
    private func client(forType type: ClientType, file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        trackForMemoryLeaks(client, file: file, line: line)
        
        if type == .authenticated {
            let authenticatedClient = AuthenticatedHTTPClientDecorator(decoratee: client, apiKey: APIKey)
            trackForMemoryLeaks(authenticatedClient, file: file, line: line)
            return authenticatedClient
        } else {
            return client
        }
    }
    
    private enum ClientType {
        case authenticated
        case notAuthenticated
    }
}

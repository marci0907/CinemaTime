//  Created by Marcell Magyar on 10.12.22.

import XCTest
import CinemaTime

final class RemoteMovieImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
}

final class RemoteMovieImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestImageFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (RemoteMovieImageDataLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieImageDataLoader(client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
}

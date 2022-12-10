//  Created by Marcell Magyar on 10.12.22.

import XCTest
import CinemaTime

final class RemoteMovieImageDataLoader {
    private let baseURL: URL
    private let client: HTTPClient
    
    private struct Task: MovieImageDataLoaderTask {
        func cancel() {}
    }
    
    init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }
    
    func load(from imagePath: String, completion: @escaping (MovieImageDataLoader.Result) -> Void) -> MovieImageDataLoaderTask {
        let fullImageURL = baseURL.appendingPathComponent(imagePath)
        client.get(from: fullImageURL) { _ in }
        return Task()
    }
}

final class RemoteMovieImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestImageFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadFromImagePath_requestImageDataFromURL() {
        let imagePath = "/any.jpg"
        let (sut , client) = makeSUT()
        
        _ = sut.load(from: imagePath) { _ in }
        
        let imageURL = URL(string: baseImageURL().absoluteString + imagePath)!
        XCTAssertEqual(client.requestedURLs, [imageURL])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with baseURL: URL = URL(string: "https://base-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (RemoteMovieImageDataLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieImageDataLoader(baseURL: baseURL, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func baseImageURL() -> URL {
        URL(string: "https://base-url.com")!
    }
}

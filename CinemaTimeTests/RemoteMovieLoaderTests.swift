//  Created by Marcell Magyar on 02.12.22.

import XCTest
import CinemaTime

final class RemoteMovieLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = anyURL()
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataTwiceFromURL() {
        let url = anyURL()
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let expectedError = anyNSError()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(expectedError), when: {
            client.complete(with: expectedError)
        })
    }
    
    func test_load_deliversErrorOnInvalidDataWith200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteMovieLoader.Error.invalidData), when: {
            client.complete(with: anyData(), statusCode: 200)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        let invalidStatusCodes = [199, 201, 300, 400, 500]
        
        invalidStatusCodes.enumerated().forEach { index, statusCode in
            let receivedData = makeJSON(from: [])
            expect(sut, toCompleteWith: .failure(RemoteMovieLoader.Error.invalidData), when: {
                client.complete(with: receivedData, statusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_doesNotDeliverItemsWithoutIdOrTitleOn200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        let movie1 = makeItem(id: nil, title: "Some random movie", imagePath: "/1.jpg", overview: nil, releaseDate: nil, rating: 2.1)
        let movie2 = makeItem(id: 2, title: "Black Adam", imagePath: "/2.jpg", overview: "Some overview", releaseDate: (Date(timeIntervalSince1970: 1666137600), "2022-10-19"), rating: 7.7)
        let movie3 = makeItem(id: 3, title: nil, imagePath: "/3.jpg", overview: "Other overview", releaseDate: (Date(timeIntervalSince1970: 1590278400), "2020-05-24"), rating: 1.1)
        
        let receivedData = makeJSON(from: [movie1.json, movie2.json, movie3.json])
        expect(sut, toCompleteWith: .success([movie2.model]), when: {
            client.complete(with: receivedData, statusCode: 200)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPURLResponseWithEmptyList() {
        let receivedData = makeJSON(from: [])
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            client.complete(with: receivedData, statusCode: 200)
        })
    }
    
    func test_load_deliversItemsOn200HTTPURLResponseWithFilledList() {
        let (sut, client) = makeSUT()
        
        let movie1 = makeItem(id: 1, title: "Black Adam", imagePath: "/1.jpg", overview: nil, releaseDate: nil, rating: 7.9)
        let movie2 = makeItem(id: 2, title: "Black Panther: Wakanda Forever", imagePath: "/2.jpg", overview: "This movie is about the Black Panther", releaseDate: (Date(timeIntervalSince1970: 1667952000), "2022-11-09"), rating: nil)
        let movie3 = makeItem(id: 3, title: "Some random movie", imagePath: nil, overview: nil, releaseDate: nil, rating: nil)
        
        let receivedData = makeJSON(from: [movie1.json, movie2.json, movie3.json])
        expect(sut, toCompleteWith: .success([movie1.model, movie2.model, movie3.model]), when: {
            client.complete(with: receivedData, statusCode: 200)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSutHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteMovieLoader? = RemoteMovieLoader(url: anyURL(), client: client)
        var deliveredResult: RemoteMovieLoader.Result?
        sut?.load(completion: { deliveredResult = $0 })
        
        sut = nil
        client.complete(with: makeJSON(from: []), statusCode: 200)
        
        XCTAssertNil(deliveredResult)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with url: URL = URL(string: "https://any-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (MovieLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: MovieLoader,
        toCompleteWith expectedResult: RemoteMovieLoader.Result,
        when action: @escaping () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as NSError), (.failure(expectedError as NSError))):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeItem(
        id: Int?, title: String?, imagePath: String? = nil, overview: String? = nil, releaseDate: (date: Date, string: String)? = nil, rating: Double? = nil
    ) -> (model: Movie, json: [String: Any]) {
        let model = Movie(id: id ?? -1, title: title ?? "", imagePath: imagePath, overview: overview, releaseDate: releaseDate?.date, rating: rating)
        
        let json: [String: Any] = [
            "id": id as Any,
            "title": title as Any,
            "poster_path": imagePath as Any,
            "overview": overview as Any,
            "release_date": releaseDate?.string as Any,
            "vote_average": rating as Any
        ].compactMapValues { $0 }
        
        return (model, json)
    }
    
    private func makeJSON(from moviesJSON: [[String: Any]]) -> Data {
        let json = ["results": moviesJSON]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}

//  Created by Marcell Magyar on 02.12.22.

import XCTest
import CinemaTime

protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

struct RemoteMovie: Decodable {
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

final class RemoteMovieLoader {
    private let url: URL
    private let client: HTTPClient
    
    typealias Result = MovieLoader.Result
    
    enum Error: Swift.Error {
        case invalidData
    }
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping (MovieLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                if response.statusCode == 200, let remoteMovies = RemoteMovieLoader.map(data) {
                    completion(.success(remoteMovies.toModels()))
                } else {
                    return completion(.failure(Error.invalidData))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private struct Root: Decodable {
        let results: [RemoteMovie]
    }
    
    private static func map(_ data: Data) -> [RemoteMovie]? {
        do {
            let movies = try JSONDecoder().decode(Root.self, from: data)
            return movies.results
        } catch {
            return nil
        }
    }
}

extension Array where Element == RemoteMovie {
    func toModels() -> [Movie] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return compactMap { remoteMovie -> Movie? in
            guard let id = remoteMovie.id, let title = remoteMovie.title else { return nil }
            
            return Movie(
                id: id,
                title: title,
                imagePath: remoteMovie.posterPath,
                overview: remoteMovie.overview,
                releaseDate: dateFormatter.date(from: remoteMovie.releaseDate),
                rating: remoteMovie.voteAverage)
        }
    }
}

extension DateFormatter {
    func date(from string: String?) -> Date? {
        guard let string = string else {
            return nil
        }
        return date(from: string)
    }
}

final class RemoteMovieLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataTwiceFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let expectedError = NSError(domain: "a domain", code: 0)
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(expectedError), when: {
            client.complete(with: expectedError)
        })
    }
    
    func test_load_deliversErrorOnInvalidDataWith200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteMovieLoader.Error.invalidData), when: {
            client.complete(with: Data("".utf8), statusCode: 200)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        let invalidStatusCodes = [199, 201, 300, 400, 500]
        
        invalidStatusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .failure(RemoteMovieLoader.Error.invalidData), when: {
                client.complete(with: Data("".utf8), statusCode: statusCode, at: index)
            })
        }
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
        let movie2 = makeItem(id: 2, title: "Black Panther: Wakanda Forever", imagePath: "/2.jpg", overview: "This movie is about the Black Panther", releaseDate: Date(timeIntervalSince1970: 1667948400), rating: nil)
        let movie3 = makeItem(id: 3, title: "Some random movie", imagePath: nil, overview: nil, releaseDate: nil, rating: nil)

        let receivedData = makeJSON(from: [movie1.json, movie2.json, movie3.json])
        expect(sut, toCompleteWith: .success([movie1.model, movie2.model, movie3.model]), when: {
            client.complete(with: receivedData, statusCode: 200)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with url: URL = URL(string: "https://any-url.com")!) -> (RemoteMovieLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteMovieLoader,
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
        id: Int, title: String, imagePath: String? = nil, overview: String? = nil, releaseDate: Date? = nil, rating: Double? = nil
    ) -> (model: Movie, json: [String: Any]) {
        let model = Movie(id: id, title: title, imagePath: imagePath, overview: overview, releaseDate: releaseDate, rating: rating)
        
        var stringDate: String?
        if let releaseDate = releaseDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            stringDate = dateFormatter.string(from: releaseDate)
        }
        
        let json: [String: Any] = [
            "id": id,
            "title": title,
            "poster_path": imagePath as Any,
            "overview": overview as Any,
            "release_date": stringDate as Any,
            "vote_average": rating as Any
        ].compactMapValues { $0 }
        
        return (model, json)
    }
    
    private func makeJSON(from moviesJSON: [[String: Any]]) -> Data {
        let json = ["results": moviesJSON]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private class HTTPClientSpy: HTTPClient {
        typealias Message = (url: URL, completion: (HTTPClient.Result) -> Void)
        
        var requestedURLs: [URL] { receivedMessages.map { $0.url } }
        
        private(set) var receivedMessages = [Message]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            receivedMessages.append((url, completion))
        }
        
        func complete(with data: Data, statusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            receivedMessages[index].completion(.success((data, response)))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            receivedMessages[index].completion(.failure(error))
        }
    }
}

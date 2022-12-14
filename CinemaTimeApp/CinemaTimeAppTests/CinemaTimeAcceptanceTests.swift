//  Created by Marcell Magyar on 13.12.22.

import XCTest
import CinemaTime
import CinemaTimeiOS
@testable import CinemaTimeApp

final class CinemaTimeAcceptanceTests: XCTestCase {
    
    func test_onLaunch_movieViewControllerRendersMovieCells() {
        let sceneDelegate = SceneDelegate(httpClient: HTTPClientStub.successful(with: response))
        sceneDelegate.configure(window: UIWindow())
        
        let root = sceneDelegate.window?.rootViewController as? UINavigationController
        let moviesVC = root?.topViewController as? MoviesViewController
        
        XCTAssertEqual(moviesVC?.renderedMoviesCount, 3)
        XCTAssertEqual(moviesVC?.renderedMovieData(at: 0), makeImageData())
        XCTAssertEqual(moviesVC?.renderedMovieData(at: 1), makeImageData())
        XCTAssertEqual(moviesVC?.renderedMovieData(at: 2), makeImageData())
    }
    
    // MARK: - Helpers
    
    private func response(from url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        if url.absoluteString.contains("/any-poster.jpg") {
            XCTAssertFalse(url.absoluteString.contains(APIKey))
            return (makeImageData(), response)
        } else {
            XCTAssertEqual(url, signedURL())
            return (makeMoviesData(), response)
        }
    }
    
    private func makeMoviesData() -> Data {
        let json = ["results": [makeMovieJSON(), makeMovieJSON(), makeMovieJSON()]]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeMovieJSON() -> [String: Any] {
        return [
            "id": 2 as Any,
            "title": "title" as Any,
            "poster_path": "/any-poster.jpg" as Any,
            "overview": "overview" as Any,
            "release_date": "2022-12-13" as Any,
            "vote_average": 5.5 as Any
        ].compactMapValues { $0 }
    }
    
    private func makeImageData() -> Data {
        UIImage.make(withColor: .blue).pngData()!
    }
    
    private func signedURL() -> URL {
        URL(string: "https://api.themoviedb.org/3/movie/now_playing?language=\(Locale.tmdb)&api_key=\(APIKey)")!
    }
    
    private class HTTPClientStub: HTTPClient {
        let stub: (URL) -> HTTPClient.Result
        
        private class Task: HTTPClientTask {
            func cancel() {}
        }
        
        static func successful(with response: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub { .success(response($0)) }
        }
        
        init(stub: @escaping (URL) -> HTTPClient.Result) {
            self.stub = stub
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            completion(stub(url))
            return Task()
        }
    }
}

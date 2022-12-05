//  Created by Marcell Magyar on 05.12.22.

import XCTest
import CinemaTime

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    struct Error: Swift.Error {}
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        let urlRequest = URLRequest(url: url)
        
        session.dataTask(with: urlRequest) { _, _, _ in
            completion(.failure(Error()))
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(URLProtocolStub.self)
        URLProtocolStub.reset()
    }
    
    func test_init_doesNotExecuteRequest() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        _ = URLSessionHTTPClient(session: session)
        
        XCTAssertTrue(URLProtocolStub.shared?.receivedURLs.isEmpty == true)
    }
    
    func test_get_requestsDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { _ in
            XCTAssertEqual(URLProtocolStub.shared?.receivedURLs, [url])
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        static var shared: URLProtocolStub?
        
        override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
            
            URLProtocolStub.shared = self
        }
        
        private var _receivedURLs = [URL]()
        private let queue = DispatchQueue(label: "\(URLProtocolStub.self)Queue")
        
        var receivedURLs: [URL] {
            get { queue.sync { _receivedURLs }}
            set { queue.sync { _receivedURLs = newValue }}
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override func startLoading() {
            receivedURLs.append(request.url!)
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        static func reset() {
            shared?.receivedURLs = []
        }
    }
}

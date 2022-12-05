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
        registerStubForTests()
    }
    
    override func tearDown() {
        super.tearDown()
        unregisterStubAndReset()
    }
    
    func test_init_doesNotRequestDataFromURL() {
        _ = makeSUT()
        
        XCTAssertTrue(URLProtocolStub.shared?.receivedURLs.isEmpty == true)
    }
    
    func test_get_requestsDataFromURL() {
        let url = anyURL()
        let sut = makeSUT(with: url)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { _ in
            XCTAssertEqual(URLProtocolStub.shared?.receivedURLs, [url])
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_get_deliversErrorOnAnInvalidCaseRepresentation() {
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure: break
                
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with url: URL = URL(string: "https://any-url.com")!) -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }
    
    private func registerStubForTests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    private func unregisterStubAndReset() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        URLProtocolStub.reset()
    }
    
    private class URLProtocolStub: URLProtocol {
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static var shared: URLProtocolStub?
        
        private var _receivedURLs = [URL]()
        private let queue = DispatchQueue(label: "\(URLProtocolStub.self)Queue")
        
        private(set) var stub: Stub?
        
        var receivedURLs: [URL] {
            get { queue.sync { _receivedURLs }}
            set { queue.sync { _receivedURLs = newValue }}
        }
        
        override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
            
            URLProtocolStub.shared = self
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            shared?.stub = Stub(data: data, response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override func startLoading() {
            receivedURLs.append(request.url!)
            
            if let data = stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
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

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
        
        session.dataTask(with: urlRequest) { _, _, error in
            completion(.failure(error ?? Error()))
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
    
    func test_get_deliversErrorOnAllInvalidCaseRepresentations() {
        let sut = makeSUT()
        
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: nil, response: nil, error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: anyData(), response: anyURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: anyData(), response: anyHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: nil, response: anyHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: nil, response: anyURLResponse(), error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: nil, response: anyURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: anyData(), response: nil, error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: anyData(), response: nil, error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: anyData(), response: anyURLResponse(), error: nil)
        
        // TODO: check this case
        expect(sut, toCompleteWithErrorForInvalidRepresentationWith: nil, response: anyHTTPURLResponse(), error: nil)
    }
    
    func test_get_deliversErrorOnFailure() {
        let expectedError = NSError(domain: "Other domain", code: 5)
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.code, expectedError.code)
                XCTAssertEqual(receivedError.domain, expectedError.domain)
                
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with url: URL = URL(string: "https://any-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: URLSessionHTTPClient,
        toCompleteWithErrorForInvalidRepresentationWith data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure(error):
                XCTAssertNotNil(error, file: file, line: line)
                
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }
    
    private func anyData() -> Data {
        Data("".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse()
    }
    
    private func anyURLResponse() -> URLResponse {
        URLResponse()
    }
    
    private func anyNSError() -> Error {
        NSError(domain: "a domain", code: 0)
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
        
        private(set) static var stub: Stub?
        
        var receivedURLs: [URL] {
            get { queue.sync { _receivedURLs }}
            set { queue.sync { _receivedURLs = newValue }}
        }
        
        override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
            
            URLProtocolStub.shared = self
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override func startLoading() {
            receivedURLs.append(request.url!)
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
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
            URLProtocolStub.stub = nil
        }
    }
}

//  Created by Marcell Magyar on 05.12.22.

import XCTest
import CinemaTime

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.reset()
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
        
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: nil, response: nil, error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: anyData(), response: nonHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: anyData(), response: anyHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: nil, response: anyHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: nil, response: nonHTTPURLResponse(), error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: nil, response: nonHTTPURLResponse(), error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: anyData(), response: nil, error: nil)
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: anyData(), response: nil, error: anyNSError())
        expect(sut, toCompleteWithErrorForInvalidRepresentationWithData: anyData(), response: nonHTTPURLResponse(), error: nil)
    }
    
    func test_get_deliversErrorOnFailure() {
        let expectedError = NSError(domain: "Other domain", code: 5)
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        expect(sut, toCompleteWith: .failure(expectedError))
    }
    
    func test_get_deliversDataAndHTTPResponseOnSuccess() {
        let expectedData = anyData()
        let expectedResponse = anyHTTPURLResponse()
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)
        
        expect(sut, toCompleteWith: .success((expectedData, expectedResponse)))
    }
    
    func test_get_deliversHTTPResponseOnSuccessWithEmptyData() {
        let emptyData = Data()
        let expectedResponse = anyHTTPURLResponse()
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: emptyData, response: expectedResponse, error: nil)
        
        expect(sut, toCompleteWith: .success((emptyData, expectedResponse)))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with url: URL = URL(string: "https://any-url.com")!,
        apiKey: String = "not an empty key",
        file: StaticString = #file,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session, apiKey: apiKey)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: URLSessionHTTPClient,
        toCompleteWith expectedResult: URLSessionHTTPClient.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success((receivedData, receivedResponse)), .success((expectedData, expectedResponse))):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                XCTAssertEqual(receivedResponse.statusCode, expectedResponse.statusCode, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
                XCTAssertEqual(receivedError.domain, expectedError.domain, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(
        _ sut: URLSessionHTTPClient,
        toCompleteWithErrorForInvalidRepresentationWithData data: Data?,
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
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse()
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse()
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
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
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
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        override func stopLoading() {}
        
        static func reset() {
            shared?.receivedURLs = []
            stub = nil
        }
    }
}

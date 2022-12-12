//  Created by Marcell Magyar on 05.12.22.

import XCTest
import CinemaTime

final class URLSessionHTTPClientTests: XCTestCase, HTTPClientTest {
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.reset()
    }
    
    func test_get_requestsDataFromURL() {
        let url = anyURL()
        let sut = makeSUT(with: url)
        
        URLProtocolStub.stub(data: anyData(), response: anyHTTPURLResponse(), error: nil)
        
        let exp = expectation(description: "Wait for completion")
        _ = sut.get(from: url) { result in
            switch result {
            case let .success((_, response)):
                XCTAssertEqual(response.url, url)
                
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            
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
    
    func test_cancelingTask_cancelsURLRequestAndDeliversCancelledURLError() {
        let sut = makeSUT()
        
        let cancelledError = NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue)
        expect(sut, toCompleteWith: .failure(cancelledError), when: { $0.cancel() })
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
        _ sut: HTTPClient,
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
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static let queue = DispatchQueue(label: "\(URLProtocolStub.self)Queue")
        
        private static var _stub: Stub?
        private(set) static var stub: Stub? {
            get { queue.sync { _stub }}
            set { queue.sync { _stub = newValue }}
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func reset() {
            stub = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
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
    }
}

//  Created by Marcell Magyar on 05.12.22.

import XCTest

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_init_doesNotExecuteRequest() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let session = URLSession(configuration: config)
        _ = URLSessionHTTPClient(session: session)
        
        XCTAssertTrue(URLProtocolStub.receivedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        static let shared = URLProtocolStub()
        
        private(set) static var receivedURLs = [URL]()
    }
}

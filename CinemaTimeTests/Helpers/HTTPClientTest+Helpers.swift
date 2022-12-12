//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

protocol HTTPClientTest {}

extension HTTPClientTest where Self: XCTestCase {
    func expect(
        _ sut: HTTPClient,
        toCompleteWith expectedResult: HTTPClient.Result,
        when action: @escaping (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        let task = sut.get(from: anyURL()) { receivedResult in
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
        
        action(task)
        
        wait(for: [exp], timeout: 1.0)
    }
}

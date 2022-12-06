//  Created by Marcell Magyar on 06.12.22.

import Foundation
import CinemaTime

class HTTPClientSpy: HTTPClient {
    typealias Message = (url: URL, completion: (HTTPClient.Result) -> Void)
    
    var requestedURLs: [URL] { receivedMessages.map { $0.url } }
    
    private var receivedMessages = [Message]()
    
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

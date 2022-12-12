//  Created by Marcell Magyar on 06.12.22.

import Foundation
import CinemaTime

class HTTPClientSpy: HTTPClient {
    typealias Message = (url: URL, completion: (HTTPClient.Result) -> Void)
    
    private struct Task: HTTPClientTask {
        let action: () -> Void
        func cancel() {
            action()
        }
    }
    
    var requestedURLs: [URL] { receivedMessages.map { $0.url } }
    var cancelledURLs = [URL]()
    
    private var receivedMessages = [Message]()
    
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        receivedMessages.append((url, completion))
        return Task { [weak self] in self?.cancelledURLs.append(url) }
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

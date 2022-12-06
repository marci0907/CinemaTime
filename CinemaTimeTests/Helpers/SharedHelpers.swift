//  Created by Marcell Magyar on 05.12.22.

import Foundation

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

func anyData() -> Data {
    Data("".utf8)
}

func anyNSError() -> Error {
    NSError(domain: "a domain", code: 0)
}

func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse()
}

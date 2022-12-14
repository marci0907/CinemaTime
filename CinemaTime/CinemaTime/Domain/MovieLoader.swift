//  Created by Marcell Magyar on 02.12.22.

import Foundation

public protocol MovieLoader {
    typealias Result = Swift.Result<[Movie], Error>
    func load(completion: @escaping (Result) -> Void)
}

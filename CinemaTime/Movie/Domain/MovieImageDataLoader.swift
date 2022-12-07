//  Created by Marcell Magyar on 07.12.22.

import Foundation

public protocol MovieImageDataLoaderTask {
    func cancel()
}

public protocol MovieImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    
    func load(from url: URL, completion: @escaping (Result) -> Void) -> MovieImageDataLoaderTask
}

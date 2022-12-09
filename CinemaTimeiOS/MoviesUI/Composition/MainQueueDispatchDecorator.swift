//  Created by Marcell Magyar on 09.12.22.

import Foundation
import CinemaTime

final class MainQueueDispatchDecorator<T> {
    let decoratee: T
    
    init(decoratee: T) {
        self.decoratee = decoratee
    }
    
    func dispatch(action: @escaping () -> Void) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async(execute: action)
        }
        
        action()
    }
}

extension MainQueueDispatchDecorator: MovieImageDataLoader where T == MovieImageDataLoader {
    func load(from imagePath: String?, completion: @escaping (MovieImageDataLoader.Result) -> Void) -> MovieImageDataLoaderTask {
        decoratee.load(from: imagePath) { [weak self] result in
            self?.dispatch { completion(result) }
        }
    }
}

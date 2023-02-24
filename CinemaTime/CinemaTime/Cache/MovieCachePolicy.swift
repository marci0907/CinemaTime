//  Created by Marcell Magyar on 24.02.23.

import Foundation

final class MovieCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int { 7 }
    
    private init() {}
    
    static func validate(_ timestamp: Date, against currentTime: Date) -> Bool {
        guard let cacheExpirationDate = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return cacheExpirationDate > currentTime
    }
}

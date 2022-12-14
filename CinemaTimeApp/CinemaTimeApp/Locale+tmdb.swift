//  Created by Marcell Magyar on 14.12.22.

import Foundation

extension Locale {
    static var tmdb: String {
        if current.identifier.contains("_") {
            return current.identifier.replacingOccurrences(of: "_", with: "-")
        } else {
            return current.identifier + "-" + current.identifier.uppercased()
        }
    }
}

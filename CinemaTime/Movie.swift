//  Created by Marcell Magyar on 02.12.22.

import Foundation

public struct Movie: Equatable {
    let id: Int
    let title: String
    let image: URL?
    let overview: String?
    let releaseDate: Date?
    let rating: Double?
}

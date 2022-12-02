//  Created by Marcell Magyar on 02.12.22.

import Foundation

public struct Movie: Equatable {
    let id: Int
    let title: String
    let imagePath: String?
    let overview: String?
    let releaseDate: Date?
    let rating: Double?
    
    public init(id: Int, title: String, imagePath: String?, overview: String?, releaseDate: Date?, rating: Double?) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
        self.overview = overview
        self.releaseDate = releaseDate
        self.rating = rating
    }
}

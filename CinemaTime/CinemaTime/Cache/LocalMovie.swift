//  Created by Marcell Magyar on 24.02.23.

import Foundation

public struct LocalMovie: Equatable {
    public let id: Int
    public let title: String
    public let imagePath: String?
    public let overview: String?
    public let releaseDate: Date?
    public let rating: Double?
    
    public init(id: Int, title: String, imagePath: String?, overview: String?, releaseDate: Date?, rating: Double?) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
        self.overview = overview
        self.releaseDate = releaseDate
        self.rating = rating
    }
}

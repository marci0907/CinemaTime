//  Created by Marcell Magyar on 13.12.22.

import Foundation
import CinemaTime

func makeMovie(
    title: String = "any title",
    imagePath: String? = "/any.jpg",
    overview: String = "any overview",
    releaseDate: Date? = nil,
    rating: Double = 1.0
) -> Movie {
    Movie(id: 0, title: title, imagePath: imagePath, overview: overview, releaseDate: releaseDate, rating: rating)
}

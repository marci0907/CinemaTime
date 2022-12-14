//  Created by Marcell Magyar on 14.12.22.

import XCTest
import CinemaTime

final class MoviesLocalizationTests: XCTestCase {
    
    func test_module_supportsEnglishAndHungarianLocalizations() {
        XCTAssertEqual(Bundle(for: MoviesPresenter.self).localizations, ["en", "hu"])
    }
}

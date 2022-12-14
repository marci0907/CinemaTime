//  Created by Marcell Magyar on 14.12.22.

import XCTest
import CinemaTime

final class MoviesLocalizationTests: XCTestCase {
    
    func test_module_supportsEnglishAndHungarianLocalizations() {
        XCTAssertEqual(Bundle(for: MoviesPresenter.self).localizations, ["en", "hu"])
    }
    
    func test_module_hasLocalizationForAllKeysInAllSupportedLanguages() {
        let table = "Movies"
        let bundle = Bundle(for: MoviesPresenter.self)
        let localizations = allLocalizations(for: table, in: bundle)
        let allUniqueLocalizedKeys = allLocalizedKeys(in: localizations, for: table)
        
        localizations.forEach { localization in
            allUniqueLocalizedKeys.forEach { key in
                let localizedString = localization.bundle.localizedString(forKey: key, value: nil, table: table)
                if localizedString == key {
                    let language = language(for: localization.localization)
                    return XCTFail("Missing \(language) (\(localization.localization)) localization for key \(key) in table: '\(table)'")
                }
            }
        }
    }
    
    private struct Localization {
        let localization: String
        let bundle: Bundle
    }
    
    private func allLocalizations(for table: String, in bundle: Bundle, file: StaticString = #file, line: UInt = #line) -> [Localization] {
        var allLocalizations = [Localization]()
        bundle.localizations.forEach {
            guard let path = bundle.path(forResource: $0, ofType: "lproj", inDirectory: nil),
                  let bundle = Bundle(path: path) else {
                let language = language(for: $0)
                XCTFail("Missing \($0).lproj file for localization \(language) (\($0))", file: file, line: line)
                return
            }
            
            allLocalizations.append(Localization(localization: $0, bundle: bundle))
        }
        return allLocalizations
    }
    
    private func allLocalizedKeys(in localizations: [Localization], for table: String, file: StaticString = #file, line: UInt = #line) -> Set<String> {
        var allLocalizedKeys = Set<String>()
        
        localizations.forEach { localization in
            guard let path = localization.bundle.path(forResource: table, ofType: "strings") else {
                let language = language(for: localization.localization)
                XCTFail("Missing \(table).strings file for localization \(language) (\(localization.localization))", file: file, line: line)
                return
            }
            localizedKeys(at: path).forEach { allLocalizedKeys.insert($0) }
        }
        
        return allLocalizedKeys
    }
    
    private func localizedKeys(at path: String, file: StaticString = #file, line: UInt = #line) -> [String] {
        return NSDictionary(contentsOfFile: path)?.allKeys as? [String] ?? []
    }
    
    private func language(for localization: String) -> String {
        Locale.current.localizedString(forLanguageCode: localization) ?? ""
    }
}

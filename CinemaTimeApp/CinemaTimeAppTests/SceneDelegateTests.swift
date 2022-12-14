//  Created by Marcell Magyar on 13.12.22.

import XCTest
import CinemaTimeiOS
@testable import CinemaTimeApp

final class SceneDelegateTests: XCTestCase {
    
    func test_sceneWillConnectToSession_setsWindowsRootViewController() {
        let sceneDelegate = SceneDelegate()
        
        sceneDelegate.configure(window: UIWindow())
        
        let root = sceneDelegate.window?.rootViewController
        XCTAssertTrue(root is UINavigationController)
        XCTAssertTrue((root as? UINavigationController)?.topViewController is MoviesViewController)
    }
    
    func test_sceneWillConnectToSession_setsWindowVisible() {
        let sceneDelegate = SceneDelegate()
        
        sceneDelegate.configure(window: UIWindow())
        
        XCTAssertFalse(sceneDelegate.window?.isHidden ?? false)
    }
}

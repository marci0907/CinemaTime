//  Created by Marcell Magyar on 12.12.22.

import UIKit
import CinemaTime
import CinemaTimeiOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    private lazy var httpClient: HTTPClient = {
        return URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()
    
    convenience init(httpClient: HTTPClient) {
        self.init()
        self.httpClient = httpClient
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        configure(window: window)
    }
    
    func configure(window: UIWindow) {
        let authenticatedClient = AuthenticatedHTTPClientDecorator(decoratee: httpClient, apiKey: APIKey)
        
        let movieLoader = RemoteMovieLoader(
            url: URL(string: "https://api.themoviedb.org/3/movie/now_playing?language=\(Locale.tmdb)")!,
            client: authenticatedClient)
        
        let imageLoader = RemoteMovieImageDataLoader(baseURL: URL(string: "https://image.tmdb.org/t/p/w500/")!, client: httpClient)
        
        let moviesViewController = MoviesUIComposer.viewController(movieLoader: movieLoader, imageLoader: imageLoader)
        
        self.window = window
        self.window?.rootViewController = UINavigationController(rootViewController: moviesViewController)
        self.window?.makeKeyAndVisible()
    }
}

extension Locale {
    static var tmdb: String {
        if current.identifier.contains("_") {
            return current.identifier.replacingOccurrences(of: "_", with: "-")
        } else {
            return current.identifier + "-" + current.identifier.uppercased()
        }
    }
}

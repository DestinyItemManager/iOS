import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    // If our app is launched with a universal link, we'll store it in this variable
    static var universalLinkToLaunch: URL? = nil
    
    // This function is called when your app launches.
    // Check to see if we were launched via a universal link or a shortcut.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // See if our app is being launched via universal link.
        // If so, store that link so we can navigate to it once our webView is initialized.
        for userActivity in connectionOptions.userActivities {
            if let universalLink = userActivity.webpageURL, let dimURL = getDIMUrl(url: universalLink) {
                SceneDelegate.universalLinkToLaunch = dimURL;
                break
            }
        }
        
        // See if we were launched via shortcut
        if let shortcutUrlStr = connectionOptions.shortcutItem?.type,
            let shortcutUrl = URL.init(string: shortcutUrlStr),
            let dimURL = getDIMUrl(url: shortcutUrl) {
            SceneDelegate.universalLinkToLaunch = dimURL
        }
    }
    
    // This function is called when our app is already running and the user clicks a universal link.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Handle universal links into our app when the app is already running.
        // This allows your PWA to open links to your domain, rather than opening in a browser tab.
        // For more info about universal links, see https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app
        
        // Ensure we're trying to launch a link.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let universalLink = userActivity.webpageURL else {
            return
        }
        
        loadDIMUrl(url: universalLink)
    }
    
    // This function is called if our app is already loaded and the user activates the app via shortcut
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let shortcutUrl = URL.init(string: shortcutItem.type) {
            loadDIMUrl(url: shortcutUrl)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // Load a DIM URL in an already-running instance of the app
    func loadDIMUrl(url: URL) {
        guard let dimURL = getDIMUrl(url: url) else {
            return
        }
        
        // Handle it inside our web view in a SPA-friendly way.
        DIM.webView.evaluateJavaScript("location.href = '\(dimURL.absoluteString)'")
    }
    
    // Return a version of the input URL that's always on the app.destinyitemmanager.com domain, both as a
    // security measure and so beta -> app.
    func getDIMUrl(url: URL) -> URL? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        // Even if it's a beta URL, load in app
        urlComponents.host = allowedOrigin
        
        guard let dimURL = urlComponents.url else {
            return nil
        }
        
        return dimURL
    }
}


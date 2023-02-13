import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window : UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        builder.remove(menu: .services)
        builder.remove(menu: .hide)
        builder.remove(menu: .window)
        builder.remove(menu: .file)
        builder.remove(menu: .edit)
        builder.remove(menu: .format)
        builder.remove(menu: .view)
        builder.remove(menu: .help)
        
        builder.insertSibling(UIMenu(
            title: "",
            options: .displayInline,
            children: [
                UIKeyCommand(title: "Preferences...",
                             action: #selector(openPreferences),
                             input: ",",
                             modifierFlags: .command),
                UICommand(title: "Usage guide",
                          action: #selector(openWiki)),
                UICommand(title: "@ThisIsDIM",
                          action: #selector(openTwitter))]
        ), afterMenu: .about)
    }
    
    @objc func openPreferences() {
        DIM.webView.load(URLRequest(url: URL(string:"https://app.destinyitemmanager.com/settings")!));
    }
    @objc func openWiki() {
        let url = URL(string: "https://github.com/DestinyItemManager/DIM/wiki")!
        UIApplication.shared.open(url)
    }
    @objc func openTwitter() {
        let url = URL(string: "https://twitter.com/ThisIsDIM")!
        UIApplication.shared.open(url)
    }
}

import UIKit
import WebKit
import AuthenticationServices
import SafariServices


func createWebView(container: UIView, WKSMH: WKScriptMessageHandler, WKND: WKNavigationDelegate, NSO: NSObject, VC: ViewController) -> WKWebView{
    
    let config = WKWebViewConfiguration()
    let userContentController = WKUserContentController()

    userContentController.add(WKSMH, name: "print")
    userContentController.add(WKSMH, name: "push-subscribe")
    userContentController.add(WKSMH, name: "push-permission-request")
    userContentController.add(WKSMH, name: "push-permission-state")
    config.userContentController = userContentController
    
    if #available(iOS 14, *) {
        config.limitsNavigationsToAppBoundDomains = true;
        
    }
    config.preferences.javaScriptCanOpenWindowsAutomatically = true
    config.allowsInlineMediaPlayback = true
    config.preferences.setValue(true, forKey: "standalone")

    // Append the safari UA to the end so that Stadia (Google login) works.
    // https://github.com/pwa-builder/pwabuilder-ios/issues/30
    config.applicationNameForUserAgent = "Safari/604.1"
    

    let webView = WKWebView(frame: calcWebviewFrame(webviewView: container, toolbarView: nil), configuration: config)
    
    setCustomCookie(webView: webView)

    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    webView.isHidden = true;

    webView.navigationDelegate = WKND;

    webView.scrollView.bounces = false;
    webView.allowsBackForwardNavigationGestures = false
    

    webView.scrollView.contentInsetAdjustmentBehavior = .never


    webView.addObserver(NSO, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: NSKeyValueObservingOptions.new, context: nil)
    
    return webView
}

func setAppStoreAsReferrer(contentController: WKUserContentController) {
    let scriptSource = "document.referrer = `app-info://platform/ios-store`;"
    let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    contentController.addUserScript(script);
}

func setCustomCookie(webView: WKWebView) {
    let _platformCookie = HTTPCookie(properties: [
        .domain: rootUrl.host!,
        .path: "/",
        .name: platformCookie.name,
        .value: platformCookie.value,
        .secure: "FALSE",
        .expires: NSDate(timeIntervalSinceNow: 31556926)
    ])!

    webView.configuration.websiteDataStore.httpCookieStore.setCookie(_platformCookie)

}

func calcWebviewFrame(webviewView: UIView, toolbarView: UIToolbar?) -> CGRect{
    if ((toolbarView) != nil) {
        return CGRect(x: 0, y: toolbarView!.frame.height, width: webviewView.frame.width, height: webviewView.frame.height - toolbarView!.frame.height)
    }
    else {
        let winScene = UIApplication.shared.connectedScenes.first
        let windowScene = winScene as! UIWindowScene
        var statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height ?? 0
        
        switch displayMode {
        case "fullscreen":
            statusBarHeight = 0
            #if targetEnvironment(macCatalyst)
                if let titlebar = windowScene.titlebar {
                    titlebar.titleVisibility = .hidden
                    titlebar.toolbar = nil
                    statusBarHeight = 26
                }
            #endif
            let windowHeight = webviewView.frame.height - statusBarHeight
            return CGRect(x: 0, y: statusBarHeight, width: webviewView.frame.width, height: windowHeight)
        default:
            #if targetEnvironment(macCatalyst)
            statusBarHeight = 29
            #endif
            let windowHeight = webviewView.frame.height - statusBarHeight
            return CGRect(x: 0, y: statusBarHeight, width: webviewView.frame.width, height: windowHeight)
        }
    }
}

//func createStatusBar(container: UIView) -> UIView {
//    let app = UIApplication.shared
//    let statusBarHeight: CGFloat = app.statusBarFrame.size.height
//
//    let statusBarView = UIView()
//    statusBarView.backgroundColor = hexStringToUIColor(hex: statusBarColor)
//    container.addSubview(statusBarView)
//
//    statusBarView.translatesAutoresizingMaskIntoConstraints = false
//    statusBarView.heightAnchor
//      .constraint(equalToConstant: statusBarHeight).isActive = true
//    statusBarView.widthAnchor
//      .constraint(equalTo: container.widthAnchor, multiplier: 1.0).isActive = true
//    statusBarView.topAnchor
//      .constraint(equalTo: container.topAnchor).isActive = true
//    statusBarView.centerXAnchor
//      .constraint(equalTo: container.centerXAnchor).isActive = true
//
//    statusBarView.isHidden = true
//
//    return statusBarView
//}

//func hexStringToUIColor (hex:String) -> UIColor {
//    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//
//    if (cString.hasPrefix("#")) {
//        cString.remove(at: cString.startIndex)
//    }
//
//    if ((cString.count) != 6) {
//        return UIColor.gray
//    }
//
//    var rgbValue:UInt64 = 0
//    Scanner(string: cString).scanHexInt64(&rgbValue)
//
//    return UIColor(
//        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
//        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
//        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
//        alpha: CGFloat(1.0)
//    )
//}

extension ViewController: WKUIDelegate {
    // redirect new tabs to main webview
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let requestUrl = navigationAction.request.url{
            if let requestHost = requestUrl.host {
                if (requestHost.range(of: allowedOrigin) != nil) {
                    // Open in main webview
                    decisionHandler(.allow)
                    if (!toolbarView.isHidden) {
                        toolbarView.isHidden = true
                        webView.frame = calcWebviewFrame(webviewView: webviewView, toolbarView: nil)
                    }
                    
                } else {
                    let matchingAuthOrigin = authOrigins.first(where: { requestHost.range(of: $0) != nil })
                    //if (requestHost.range(of: authOrigin_1) != nil || requestHost.range(of: authOrigin_2) != nil || requestHost.range(of: authOrigin_3) != nil || requestHost.range(of: authOrigin_4) != nil) {
                    if (matchingAuthOrigin != nil) {
                        decisionHandler(.allow)
                        if (toolbarView.isHidden) {
                            toolbarView.isHidden = false
                            webView.frame = calcWebviewFrame(webviewView: webviewView, toolbarView: toolbarView)
                        }
                        return
                    }
                    else {
                        let ignoreHost = ignoreOrigins.first(where: { requestHost.range(of: $0) != nil })
                        if (ignoreHost != nil) {
                            decisionHandler(.cancel)
                            return;
                        }

                        if (navigationAction.navigationType == .other &&
                            navigationAction.value(forKey: "syntheticClickType") as! Int == 0 &&
                            (navigationAction.targetFrame != nil)
                        ) {
                            decisionHandler(.allow)
                            return
                        }
                        else {
                            decisionHandler(.cancel)
                        }
                    }
                    

                    if ["http", "https"].contains(requestUrl.scheme?.lowercased() ?? "") {
                         // Can open with SFSafariViewController
                         let safariViewController = SFSafariViewController(url: requestUrl)
                         self.present(safariViewController, animated: true, completion: nil)
                     } else {
                         // Scheme is not supported or no scheme is given, use openURL
                        if (UIApplication.shared.canOpenURL(requestUrl)) {
                            UIApplication.shared.open(requestUrl)
                        }
                     }
                    
                }
            } else {
                decisionHandler(.cancel)
                if (navigationAction.request.url?.scheme == "tel" || navigationAction.request.url?.scheme == "mailto" ){
                    if (UIApplication.shared.canOpenURL(requestUrl)) {
                        UIApplication.shared.open(requestUrl)
                    }
                }
            }
        }
        else {
            decisionHandler(.cancel)
        }
        
    }
    func webView(_ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void) {
        
        // Set the message as the UIAlertController message
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )

        // Add a confirmation action “OK”
        let okAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                // Call completionHandler
                completionHandler()
            }
        )
        alert.addAction(okAction)

        // Display the NSAlert
        present(alert, animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void) {

        // Set the message as the UIAlertController message
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        // Add a confirmation action “Cancel”
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
                // Call completionHandler
                completionHandler(false)
            }
        )
        
        // Add a confirmation action “OK”
        let okAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                // Call completionHandler
                completionHandler(true)
            }
        )
        alert.addAction(cancelAction)
        alert.addAction(okAction)

        // Display the NSAlert
        present(alert, animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void) {

        // Set the message as the UIAlertController message
        let alert = UIAlertController(
            title: nil,
            message: prompt,
            preferredStyle: .alert
        )
        
        // Add a confirmation action “Cancel”
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
                // Call completionHandler
                completionHandler(nil)
            }
        )
        
        // Add a confirmation action “OK”
        let okAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                // Call completionHandler with Alert input
                if let input = alert.textFields?.first?.text {
                    completionHandler(input)
                }
            }
        )
        
        alert.addTextField { textField in
            textField.placeholder = defaultText
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)

        // Display the NSAlert
        present(alert, animated: true, completion: nil)
    }
}

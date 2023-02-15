import UIKit
import WebKit
import AuthenticationServices
import SafariServices


func createWebView(container: UIView, WKSMH: WKScriptMessageHandler, WKND: WKNavigationDelegate, NSO: NSObject, VC: ViewController) -> WKWebView {
    
    let config = WKWebViewConfiguration()
    let userContentController = WKUserContentController()
    config.userContentController = userContentController
    config.limitsNavigationsToAppBoundDomains = true
    config.preferences.javaScriptCanOpenWindowsAutomatically = true
    config.allowsInlineMediaPlayback = true
    config.preferences.setValue(true, forKey: "standalone")

    let bundleInfo = Bundle.main.infoDictionary!
    let version = bundleInfo["CFBundleShortVersionString"] as! String
    
    // This is needed for the DIM web app to recognize this version
    config.applicationNameForUserAgent = "DIM AppStore \(version)"
    
    let webView = WKWebView(frame: calcWebviewFrame(webviewView: container, toolbarView: nil), configuration: config)
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    webView.isHidden = true;
    webView.navigationDelegate = WKND;
    webView.scrollView.bounces = false;
    webView.allowsBackForwardNavigationGestures = false
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    webView.addObserver(NSO, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: NSKeyValueObservingOptions.new, context: nil)
    
    return webView
}

func calcWebviewFrame(webviewView: UIView, toolbarView: UIToolbar?) -> CGRect{
    if toolbarView != nil {
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

extension ViewController: WKDownloadDelegate {    
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        // First save to a temp directory. This generates a unique temp directory
        let temporaryDirectoryURL =
            (try? FileManager.default.url(for: .itemReplacementDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: FileManager.default.temporaryDirectory,
                                        create: true)) ?? FileManager.default.temporaryDirectory
        // Add our filenam
        let fileUrl = temporaryDirectoryURL
                        .appendingPathComponent(suggestedFilename, isDirectory: false)
        // Remember this download
        downloadMap.setObject(fileUrl as NSURL, forKey: download)
        completionHandler(fileUrl)
            
    }
    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("Download error \(error)")
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        // Fish the remembered download from the map. No need to delete it, ARC will handle that
        if let fileUrl = downloadMap.object(forKey: download) {
            share(url: fileUrl as URL)
        } else {
            print("Unknown download \(download)")
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        htmlIsLoaded = true;
        
        self.setProgress(1.0, true);
        self.animateConnectionProblem(false);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            DIM.webView.isHidden = false;
            self.loadingView.isHidden = true;
            
            self.setProgress(0.0, false);
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        htmlIsLoaded = false;
        
        if (error as NSError)._code != (-999) {
            webView.isHidden = true;
            loadingView.isHidden = false;
            animateConnectionProblem(true);
            
            setProgress(0.05, true);
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.setProgress(0.1, true);
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.loadRootUrl();
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
        
    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        }
        
        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        guard let requestHost = requestUrl.host else {
            decisionHandler(.cancel)
            
            // Support mail/phone links anyway
            if navigationAction.request.url?.scheme == "tel" || navigationAction.request.url?.scheme == "mailto" {
                if (UIApplication.shared.canOpenURL(requestUrl)) {
                    UIApplication.shared.open(requestUrl)
                }
            }
            return
        }
        
        // If this is app.destinyitemmanager.com, just go there
        if requestHost == allowedOrigin {
            // Open in main webview
            decisionHandler(.allow)
            if !toolbarView.isHidden {
                toolbarView.isHidden = true
                webView.frame = calcWebviewFrame(webviewView: webviewView, toolbarView: nil)
            }
            return
        }
        
        // Handle clicking the bungie login button
        if requestUrl.absoluteString.hasPrefix(bungieLogin) {
            decisionHandler(.cancel)
            // DIM's authReturn.ts will redirect to this special dimauth:// scheme to indicate we're done
            let session = ASWebAuthenticationSession(url: requestUrl, callbackURLScheme: "dimauth")
            { callbackURL, error in
                if error != nil || callbackURL == nil {
                    return
                }
                
                guard var urlComponents = URLComponents(url: callbackURL!, resolvingAgainstBaseURL: true) else {
                    return
                }
                // Change the scheme back to https
                urlComponents.scheme = "https"
                
                guard let authURL = urlComponents.url else {
                    return
                }
                print(authURL)
                webView.load(URLRequest(url: authURL))
            }
            session.presentationContextProvider = webView.parentViewController as? any ASWebAuthenticationPresentationContextProviding
            session.start()
            return
        }
        
        // Allow frames to load
        if navigationAction.navigationType == .other &&
            navigationAction.value(forKey: "syntheticClickType") as! Int == 0 &&
            navigationAction.targetFrame != nil
        {
            decisionHandler(.allow)
            return
        }
        
        // External links get handled with a popup
        decisionHandler(.cancel)
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
    
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
        
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}

extension ViewController: WKUIDelegate {
    // redirect new tabs to main webview
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // Handle javascript: `window.alert(message: String)`
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
    // Handle javascript: `window.confirm(message: String)`
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
    // Handle javascript: `window.prompt(prompt: String, defaultText: String?)`
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

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}

extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}


extension UIView {
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

import UIKit
import WebKit

var webView: WKWebView! = nil

class ViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var connectionProblemView: UIImageView!
    @IBOutlet weak var webviewView: UIView!
    @IBOutlet weak var splashBkgView: UIView!;
    var statusBarView: UIView!
    var toolbarView: UIToolbar!
    var htmlIsLoaded = false;
    
    // For sharing files
    let documentInteractionController = UIDocumentInteractionController()
    
    // Keep track of downloading files. Maps (weak WKDownload => file URL)
    var downloadMap: NSMapTable<NSObject, NSURL> = NSMapTable.weakToStrongObjects()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return statusBarStyle;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initWebView()
        initToolbarView()
        loadRootUrl()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification , object: nil)
        
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        DIM.webView.setNeedsLayout()
    }
    
    func initWebView() {
        DIM.webView = createWebView(container: webviewView, WKSMH: self, WKND: self, NSO: self, VC: self)
        webviewView.addSubview(DIM.webView);
        DIM.webView.uiDelegate = self;
        DIM.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    func createToolbarView() -> UIToolbar{
        let statusBarHeight = getStatusBarHeight()
        let toolbarView = UIToolbar(frame: CGRect(x: 0, y: 0, width: webviewView.frame.width, height: 0))
        toolbarView.sizeToFit()
        toolbarView.frame = CGRect(x: 0, y: 0, width: webviewView.frame.width, height: toolbarView.frame.height + statusBarHeight)
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let close = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(loadRootUrl))
        toolbarView.setItems([close,flex], animated: true)
        
        toolbarView.isHidden = true
        
        return toolbarView
    }
    
    func getStatusBarHeight() -> CGFloat {
        let winScene = UIApplication.shared.connectedScenes.first
        let windowScene = winScene as! UIWindowScene
        var statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height ?? 60
        
#if targetEnvironment(macCatalyst)
        if (statusBarHeight == 0) {
            statusBarHeight = 30
        }
#endif
        
        return statusBarHeight;
    }
    
    func initToolbarView() {
        toolbarView =  createToolbarView()
        webviewView.addSubview(toolbarView)
        
        // Set the top of the splashBkgView to the bottom of the status bar.
        let statusBarHeight = getStatusBarHeight()
        let splashBkgFrame = self.splashBkgView.frame
        self.splashBkgView.frame = CGRect(x: splashBkgFrame.minX, y: statusBarHeight, width: splashBkgFrame.width, height: splashBkgFrame.height)
    }
    
    @objc func loadRootUrl() {
        // Was the app launched via a universal link? If so, navigate to that.
        // Otherwise, see if we were launched via shortcut and nav to that.
        // If neither, just nav to the main PWA URL.
        let launchUrl = SceneDelegate.universalLinkToLaunch ?? SceneDelegate.shortcutLinkToLaunch ?? rootUrl;
        DIM.webView.load(URLRequest(url: launchUrl))
    }
    
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
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if #available(iOS 14.5, *) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download, preferences)
            } else {
                decisionHandler(.allow, preferences)
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if #available(iOS 14.5, *) {
            if navigationResponse.canShowMIMEType {
                decisionHandler(.allow)
            } else {
                decisionHandler(.download)
            }
        }
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
        
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == #keyPath(WKWebView.estimatedProgress) &&
            DIM.webView.isLoading &&
            !self.loadingView.isHidden &&
            !self.htmlIsLoaded) {
            var progress = Float(DIM.webView.estimatedProgress);
            
            if (progress >= 0.8) { progress = 1.0; };
            if (progress >= 0.3) { self.animateConnectionProblem(false); }
            
            self.setProgress(progress, true);
            
        }
    }
    
    func setProgress(_ progress: Float, _ animated: Bool) {
        self.progressView.setProgress(progress, animated: animated);
    }
    
    func showStatusBar(_ show: Bool) {
        if (self.statusBarView != nil) {
            self.statusBarView.isHidden = !show
        }
    }
    
    func animateConnectionProblem(_ show: Bool) {
        if (show) {
            self.connectionProblemView.isHidden = false;
            self.connectionProblemView.alpha = 0
            UIView.animate(withDuration: 0.7, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.connectionProblemView.alpha = 1
            })
        }
        else {
            UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
                self.connectionProblemView.alpha = 0 // Here you will get the animation you want
            }, completion: { _ in
                self.connectionProblemView.isHidden = true;
                self.connectionProblemView.layer.removeAllAnimations();
            })
        }
    }
    
    deinit {
        DIM.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    // Show a share sheet for a downloaded file
    func share(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.delegate = self
        documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    // Whenever the share sheet is dismissed
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        if let fileUrl = controller.url {
            do {
                // Remove the temp directory once we're done sharing it
                try FileManager.default.removeItem(at: fileUrl.deletingLastPathComponent())
            } catch {
                print("Error")
            }
        }
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}

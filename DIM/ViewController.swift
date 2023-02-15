import UIKit
import AuthenticationServices
import WebKit

var webView: WKWebView! = nil

class ViewController: UIViewController {
    
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
        let launchUrl = SceneDelegate.universalLinkToLaunch ?? rootUrl;
        DIM.webView.load(URLRequest(url: launchUrl))
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

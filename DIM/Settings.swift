import WebKit

struct Cookie {
    var name: String
    var value: String
}

let gcmMessageIDKey = "00000000000" //pwashellz: update this with actual ID if using Firebase 

// URL for first launch
let rootUrl = URL(string: "https://app.destinyitemmanager.com/index.html?utm_source=homescreen")!

// allowed origin is for what we are sticking to pwa domain
// This should also appear in Info.plist
let allowedOrigin = "app.destinyitemmanager.com/index.html?utm_source=homescreen"

// auth origins will open in modal and show toolbar for back into the main origin.
// These should also appear in Info.plist
let authOrigins: [String] = []

let platformCookie = Cookie(name: "app-platform", value: "iOS App Store")


//let statusBarColor = "#FFFFFF"
//let statusBarStyle = UIStatusBarStyle.lightContent

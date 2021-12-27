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
let allowedOrigin = "app.destinyitemmanager.com"

// auth origins will open in modal and show toolbar for back into the main origin.
// These should also appear in Info.plist
let authOrigins: [String] = ["www.bungie.net", "login.live.com", "accounts.google.com", "accounts.youtube.com", "ca.account.sony.com", "my.account.sony.com", "steamcommunity.com", "id.twitch.tv"]

// These cause DIM to open a new window that shows "done"
let ignoreOrigins: [String] = ["tr.snapchat.com", "syndication.twitter.com", "store.steampowered.com", "help.steampowered.com"]

let platformCookie = Cookie(name: "app-platform", value: "iOS App Store")

let displayMode = "fullscreen" //standalone / fullscreen

//let statusBarColor = "#FFFFFF"
let statusBarStyle = UIStatusBarStyle.lightContent

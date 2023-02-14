import WebKit

// allowed origin is for what we are sticking to pwa domain
// This should also appear in Info.plist
let allowedOrigin = "app.destinyitemmanager.com"

// URL for first launch
let rootUrl = URL(string: "https://\(allowedOrigin)/?utm_source=ios_app")!

let bungieLogin = "https://www.bungie.net/en/OAuth/Authorize"

let displayMode = "fullscreen" //standalone / fullscreen

let statusBarStyle = UIStatusBarStyle.lightContent

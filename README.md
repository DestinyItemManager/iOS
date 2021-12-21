# DIM for iOS

This project was bootstraped from https://www.pwabuilder.com/ for https://app.destinyitemmanager.com

## Quick start

- `git clone https://github.com/DestinyItemManager/iOS`
- `cd iOS`
- `pod install` (`sudo gem install cocoapods`, if needed.)
- Open `DIM.xcworkspace`

## Deploying

Should be a paired down version of [pwabuilder-ios/submit-to-app-store.md](https://github.com/pwa-builder/pwabuilder-ios/blob/main/submit-to-app-store.md)

## Further reading

More information about getting started https://github.com/pwa-builder/pwabuilder-ios/blob/main/next-steps.md


---

# How this was bootstraped
1. https://pwabuilder.com/ -- enter domain name. 
2. Click the iOS option, and before hitting generate enter in under "Permitted URLs" in the settings in the dialog popup: 
`www.bungie.net, login.live.com, accounts.google.com, accounts.youtube.com, ca.account.sony.com, my.account.sony.com, steamcommunity.com, id.twitch.tv`
4. Generate and then look at WebView.swift to see how to set some ignore hosts https://github.com/DestinyItemManager/iOS/blob/main/DIM/WebView.swift#L160-L164
5. Add `config.applicationNameForUserAgent = "Safari/604.1"` to fix the Stadia login in WebView.swift (details https://github.com/pwa-builder/pwabuilder-ios/issues/30#issuecomment-997607693)
6. Follow the rest of the PWA steps to deploy.

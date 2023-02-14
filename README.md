# DIM for iOS

This project was bootstrapped from https://www.pwabuilder.com/ for https://app.destinyitemmanager.com

## Quick start

- `git clone https://github.com/DestinyItemManager/iOS`
- `cd iOS`
- `pod install` (`sudo gem install cocoapods`, if needed.)
- `open DIM.xcworkspace`

## Deploying

- Should be a pared down version of the publish step on the PWA Builder site found here: https://docs.pwabuilder.com/#/builder/app-store?id=publishing

- Once you have your local machine setup with the certificat/provisioning file/etc you should be able to jump straight to steps 6 -> 8 

## Further reading

More information about iOS & PWA's from PWA builder: https://docs.pwabuilder.com/#/builder/app-store


---

# How this was bootstrapped
1. https://pwabuilder.com/ -- enter domain name.
2. Click the iOS option, and before hitting generate enter in under "Permitted URLs" in the settings in the dialog popup:
`www.bungie.net, login.live.com, accounts.google.com, accounts.youtube.com, ca.account.sony.com, my.account.sony.com, steamcommunity.com, id.twitch.tv`
4. Generate and then look at [WebView.swift](https://github.com/DestinyItemManager/iOS/blob/main/DIM/WebView.swift#L160-L164) to see how to set some ignore hosts
5. Add `config.applicationNameForUserAgent = "Safari/604.1"` to fix the Stadia login in WebView.swift [more details here](https://github.com/pwa-builder/pwabuilder-ios/issues/30#issuecomment-997607693)
6. Follow the rest of the PWA steps to deploy.

# Security & Bug-Fix Update — October 2026

Everything changed in the `security-updates-2026` branch, and why.

## 1. App Transport Security was turned off for the whole app

`Info.plist` had `NSAllowsArbitraryLoads = true`, which lets the app make **unencrypted HTTP**
connections to any server. Anyone on the same Wi-Fi could read or change the data. App Review
also asks for a justification for this setting, and a missing one is a common rejection reason.

**Fix:** the setting was removed. The search API already uses `https://`. School image links that
come back as `http://` are upgraded to `https://` in code (`URL.secureImageURL(from:)`).

> If some school images stop loading, the image server doesn't support HTTPS. The right fix is a
> *narrow* exception for only that one domain (`NSExceptionDomains` in Info.plist), never
> re-enabling arbitrary loads for the whole app.

## 2. Search text was pasted directly into the URL (crash + query injection)

`SchoolRequest` built the URL with string interpolation:

```swift
"https://api.superfanu.com/...search?search=\(searchTerm)"
```

- Searching for anything with a space, `&`, `#`, or an apostrophe made `URL(string:)` return
  `nil`, which hit `fatalError()`. **The app crashed.** Try searching "St. Mary's" on the old build.
- Typing `blue&other=value` could add extra parameters to the API call.

**Fix:** the URL is built with `URLComponents` and `URLQueryItem`, which percent-encode the text.
No more `fatalError()`.

## 3. Crash fixes

| Crash | Fix |
|---|---|
| `schoolData[0]` when the API returned an empty list | `schoolResponse.data.first ?? []` |
| `self!` in network callbacks if the screen was closed before results arrived | `guard let self` |
| `URL(string: detailSchool.img)!` when a school had a missing or bad image link | Image is skipped safely |
| Force casts (`as!`) and force unwraps (`!`) on the split view in `AppDelegate` and `MasterViewController` | Safe `as?` / `guard` checks |

## 4. Other improvements

- Network errors and non-200 HTTP responses show a "Search failed" alert instead of silently
  showing an empty list.
- Images download with `URLSession` instead of `Data(contentsOf:)`. Apple warns against using that
  on network URLs: it blocks a thread with no timeout.
- Requests time out after 15 seconds.
- A slow image from a previous school can't overwrite the current one.
- Images over 10 MB are ignored.
- Blank searches are ignored, and the keyboard closes after searching.
- `@UIApplicationMain` → `@main` (the old attribute is deprecated).

## 5. Project settings

- **Minimum iOS version: 12.4 → 15.0.** Current Xcode no longer supports building for iOS 12.

## 6. Before resubmitting to the App Store

> **Blocker: there is no app icon.** `Assets.xcassets/AppIcon` has 0 of 18 images, and App Store
> Connect rejects uploads without a 1024×1024 icon. Add one PNG (1024×1024, no transparency), set
> AppIcon to "Single Size" in Xcode, and Xcode generates the rest.

1. Open the project in the latest Xcode and accept any "Update to recommended settings" prompt.
2. Build and run on a simulator and a real device; search a few schools, including "St. Mary's".
3. **Check that `api.superfanu.com` still responds.** This update was made without internet
   access to that server. If the API has changed or shut down, the app shows "Search failed,"
   and the request code needs a new endpoint.
4. App Store requirements (2026): build with the iOS 26 SDK (current Xcode), include a privacy
   policy URL in App Store Connect, and fill in the App Privacy "nutrition label." This app
   collects no personal data and uses none of Apple's "required reason" APIs, so a
   `PrivacyInfo.xcprivacy` manifest isn't strictly needed. Xcode will warn if that changes.

No Swift compiler was available where these changes were made, so the first Xcode build is the
real compile check. Any error will point to the exact line.

## Ongoing protection (added later in October 2026)

- **`SECURITY.md`** tells people how to report a security problem privately instead of in a public issue. For the "Report a vulnerability" button to appear, turn on **Settings → Code security → Private vulnerability reporting**.
- CodeQL scanning wasn't added here: Swift scanning needs the app to fully compile on a Mac build server, which is worth setting up once the app builds cleanly in current Xcode. You can add it later from **Settings → Code security → CodeQL analysis → Set up**.
- **Storyboard fix (found by the new automated build):** `Main.storyboard` still contained an
  old `UISearchDisplayController`, which Apple removed for apps targeting iOS 13 or later, so the
  app wouldn't compile in current Xcode. The code already uses the modern `UISearchController`
  (set up in `MasterViewController.viewDidLoad`), so the leftover object and its outlet were
  deleted. Search works exactly as before.

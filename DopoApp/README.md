# DopoApp - iOS (SwiftUI)

Native iOS app for **dopo** — your social media saves, organized.

## Requirements

- Xcode 15+
- iOS 16+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating the .xcodeproj)

## Setup

### 1. Install XcodeGen (if not already installed)

```bash
brew install xcodegen
```

### 2. Generate Xcode Project

```bash
cd DopoApp
xcodegen generate
```

This creates `DopoApp.xcodeproj` from the `project.yml` spec.

### 3. Open in Xcode

```bash
open DopoApp.xcodeproj
```

### 4. Build & Run

Select an iPhone simulator or your device, then **Cmd+R** to build and run.

## Project Structure

```
DopoApp/
├── DopoApp.swift           # App entry point
├── Info.plist               # App configuration
├── Assets.xcassets/         # App icons, colors
├── Models/
│   ├── Save.swift           # Save data model
│   └── Collection.swift     # Collection data model
├── Services/
│   ├── Config.swift         # Supabase configuration
│   ├── AuthManager.swift    # Authentication state
│   └── APIClient.swift      # REST API client
├── Extensions/
│   └── Theme.swift          # dopo design system (colors, fonts)
└── Views/
    ├── RootView.swift       # Auth routing
    ├── MainTabView.swift    # Tab navigation
    ├── Auth/
    │   └── AuthView.swift   # Login/signup
    ├── Library/
    │   └── LibraryView.swift # Main feed
    ├── Components/
    │   └── SaveCard.swift   # Card component
    ├── Player/
    │   └── SaveDetailView.swift # Detail + in-app player
    ├── Collections/
    │   └── CollectionsView.swift # Collections management
    ├── Ingest/
    │   └── IngestView.swift # Save new URLs
    └── Profile/
        └── ProfileView.swift # User profile + settings
```

## Features

- Dark-first design matching the dopo web experience
- In-app video playback (YouTube, TikTok via WKWebView)
- Platform-aware theming (YouTube red, TikTok cyan, etc.)
- Collections with owner/shared sections
- Pull-to-refresh, search, platform filters
- Paste-from-clipboard URL saving
- AI summary and tag display

## TestFlight

To distribute via TestFlight:
1. Set your Team in Xcode signing settings
2. Archive: Product → Archive
3. Distribute via App Store Connect → TestFlight

# Splitzy iOS App

SwiftUI-based iOS application for bill splitting.

## Setup Instructions

1. Open Xcode
2. Create a new iOS App project named "Splitzy"
3. Choose SwiftUI as the interface and Swift as the language
4. Copy all `.swift` files from this directory into your Xcode project
5. Update the API base URL in `APIService.swift` to point to your backend

## Project Structure

```
Splitzy/
├── Models/          # Data models
├── Services/        # API and networking
├── Views/           # SwiftUI views
│   ├── Auth/        # Authentication screens
│   ├── Home/        # Home/Bills list
│   ├── Friends/     # Friends management
│   ├── Profile/     # User profile
│   └── Bills/       # Bill details and upload
└── SplitzyApp.swift # Main app entry point
```

## Features

- User authentication (signup/login)
- Profile management with dietary preferences
- Friends management (add/remove friends)
- Bill upload with image picker
- Bills list view
- Following Apple HIG design guidelines

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Configuration

Update the `baseURL` in `APIService.swift`:
```swift
private let baseURL = "http://your-backend-url:3000/api"
```

For local development on iOS Simulator, use:
```swift
private let baseURL = "http://localhost:3000/api"
```

For testing on physical device, use your computer's IP:
```swift
private let baseURL = "http://192.168.x.x:3000/api"
```

# Splitzy iOS App

SwiftUI-based iOS application for bill splitting.

## Opening the Project

```bash
# From the repo root
open ios-app-xcode/Splitzy/Splitzy.xcodeproj
```

Or double-click `Splitzy.xcodeproj` in Finder.

## Project Structure

```
Splitzy/
├── Splitzy.xcodeproj/     # Xcode project file (open this)
├── Splitzy/               # Main app source code
│   ├── Models/            # Data models (User, Bill, etc.)
│   ├── Services/          # API & ViewModels
│   │   ├── APIService.swift
│   │   ├── AuthViewModel.swift
│   │   ├── BillsViewModel.swift
│   │   ├── FriendsViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Views/             # SwiftUI views
│   │   ├── Auth/          # Login & Signup
│   │   ├── Home/          # Bills list
│   │   ├── Bills/         # Bill upload & details
│   │   ├── Friends/       # Friends management
│   │   └── Profile/       # User profile
│   ├── Assets.xcassets/   # Images & colors
│   └── SplitzyApp.swift   # App entry point
├── SplitzyTests/          # Unit tests
└── SplitzyUITests/        # UI tests
```

## Configuration

### Update Backend URL

Edit `Splitzy/Services/APIService.swift`:

```swift
private let baseURL = "http://localhost:3000/api"  // For simulator
// or
private let baseURL = "http://192.168.x.x:3000/api"  // For physical device
```

## Running the App

1. **Select a simulator** from the top bar (e.g., iPhone 15 Pro)
2. Press **Cmd + R** or click the ▶️ play button
3. Wait for build to complete

## Requirements

- macOS 13.0+
- Xcode 14.0+
- iOS 16.0+ (deployment target)

## Testing

### Run on Simulator
- Select any iPhone simulator
- Press Cmd + R

### Run on Physical Device
1. Connect your iPhone via USB
2. Select your device from the top bar
3. Update baseURL to your computer's local IP
4. Press Cmd + R

## Common Issues

**Build fails:**
- Clean build folder: **Cmd + Shift + K**
- Rebuild: **Cmd + B**

**Can't connect to backend:**
- Ensure backend is running: `curl http://localhost:3000/health`
- Check baseURL in APIService.swift
- For device testing, use your computer's IP address

**Simulator won't launch:**
- Xcode → Window → Devices and Simulators
- Check if simulators are installed

## Editing

You can edit the Swift files in:
- **Xcode** (recommended for autocomplete and previews)
- **Cursor/VS Code** (changes auto-detected by Xcode)
- Any text editor (Xcode watches for file changes)

After editing, just press Cmd + R in Xcode to rebuild and run.

## Features

- Tab navigation (Bills/Friends/Profile)
- Authentication (signup/login)
- Bill upload with PhotosPicker
- Friends management
- Profile with dietary preferences
- Full Apple HIG compliance

## Next Steps (Phase 2)

- OpenAI Vision API integration
- Automatic receipt parsing
- Smart bill splitting based on preferences

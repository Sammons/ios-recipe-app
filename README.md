# Recipe App

Native Swift iOS recipe app built with SwiftUI and SwiftPM.

## Requirements

- Swift 6.0+
- iOS 17.0+
- [xtool](https://github.com/xtool-org/xtool) for building and deploying

## Local Development

### Install xtool

```bash
# macOS
brew install xtool-org/tap/xtool

# Linux / WSL
curl -fsSL https://xtool.sh/install.sh | bash
```

### Build

```bash
# Resolve dependencies
swift package resolve

# Build the package
swift build

# Build and run on connected iOS device via xtool
xtool build
xtool run
```

### Development mode

```bash
# Live-reload on device
xtool dev
```

## Project Structure

```
RecipeApp/
  Package.swift          # SwiftPM manifest
  xtool.yml              # iOS app metadata (bundle ID, display name, etc.)
  Sources/RecipeApp/
    RecipeApp.swift       # @main App entry point
    Views/
      ContentView.swift   # Root view
    Models/
      Recipe.swift        # Recipe data model
    ViewModels/
      RecipeListViewModel.swift  # Recipe list state
```

## CI

Gitea Actions workflow builds on every push/PR to `main` using the `macos-arm64` runner.

## Architecture

- **SwiftUI** declarative UI
- **MVVM** with `@Observable` view models
- **SwiftPM** package management (no .xcodeproj)
- **xtool** for iOS builds without Xcode project files

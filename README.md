# Ikinano

A native iOS application for running on-device language models using MediaPipe and LiteRT-LM.

> **Educational Purpose:** This project is designed for learning and educational purposes, demonstrating how to integrate and run large language models on iOS devices using both MediaPipe Tasks GenAI and Google's new LiteRT-LM framework.

## Documentation

For detailed information on implementation and building, see:
- [Architecture & Main Flow](docs/architecture-main-flow.md)
- [LiteRT-LM Implementation Notes](docs/implementation-notes.md)
- [Build & Integration Instructions](docs/build-instructions.md)
- [Gemma 4 E2B Research Plan](docs/litert-lm-gemma4-e2b-research-plan.md)

## Screenshots

<p align="center">
  <img src="screenshots/Simulator Screenshot - iPhone 17 01.png" alt="Model Download Screen" height="500">
  <img src="screenshots/Simulator Screenshot - iPhone 17 02.png" alt="Inference Screen" height="500">
</p>

## Features

- Download and manage language models locally
- Run inference on-device using MediaPipe Tasks GenAI
- Clean MVVM architecture
- SwiftUI-based user interface
- Model configuration management

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Minimum iOS Version:** 17.0
- **Dependency Manager:** CocoaPods
- **ML Framework:** MediaPipe Tasks GenAI
- **Architecture:** MVVM (Model-View-ViewModel)

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- CocoaPods installed (`sudo gem install cocoapods`)
- A language model hosted on Hugging Face (or similar service)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ikinano
```

### 2. Install Dependencies

```bash
pod install
```

### 3. Configure Model URL

The application requires a configuration file with your model URL:

1. Copy the example configuration file:
   ```bash
   cp ikinano/Config.swift.example ikinano/Config.swift
   ```

2. Edit `ikinano/Config.swift` and replace the placeholder URL with your own model URL:
   ```swift
   enum AppConfig {
       static let modelURL = "https://huggingface.co/YOUR_USERNAME/YOUR_MODEL/resolve/main/model.bin"
       static let modelFileName = "model.bin"
   }
   ```

**Note:** The `Config.swift` file is excluded from version control to keep your model URLs private.

### 4. Open the Project

```bash
open ikinano.xcworkspace
```

**Important:** Always open the `.xcworkspace` file, not the `.xcodeproj` file, when using CocoaPods.

### 5. Build and Run

1. Select your target device or simulator
2. Press `Cmd + R` to build and run the application

## Project Structure

```
ikinano/
├── Frameworks/          # LiteRT-LM XCFramework
├── Models/              # Data models and app state
├── Views/               # SwiftUI views
├── ViewModels/          # View models (MVVM)
├── Services/            # Business logic and services
│   ├── ModelFileService.swift       # Model download and validation
│   ├── LLMInferenceEngine.swift     # Engine abstraction protocol
│   ├── MediaPipeInferenceEngine.swift # MediaPipe implementation
│   ├── LiteRTLMInferenceEngine.swift  # LiteRT-LM implementation
│   └── LiteRTLM/                    # C++ Bridge and Runner
├── Repositories/        # Data persistence (SwiftData)
├── Assets.xcassets/     # Images and assets
├── Config.swift         # Feature flags and settings
└── ikinano-Bridging-Header.h # Swift-C++ interoperability
```

## How It Works

1. **Model Download:** The app downloads a quantized language model from a remote URL to the device
2. **Local Storage:** Models are stored in the app's Documents directory
3. **On-Device Inference:** MediaPipe Tasks GenAI runs the model entirely on-device
4. **No Server Required:** All processing happens locally for privacy and offline capability

## Model Requirements

The application expects:
- A `.bin` format model file (compatible with MediaPipe GenAI)
- Recommended: 2B parameter model with int4 quantization for optimal performance
- Minimum file size validation to ensure complete downloads

## Dependencies

### CocoaPods

- **MediaPipeTasksGenAI:** Framework for running LLM inference on iOS devices

To update dependencies:
```bash
pod update
```

## Configuration

### Model URL Configuration

Edit `ikinano/Config.swift`:

```swift
enum AppConfig {
    // Your Hugging Face model URL
    static let modelURL = "https://huggingface.co/username/model/resolve/main/model.bin"

    // Model filename (should match the file in the URL)
    static let modelFileName = "model.bin"
}
```

### Supported Model Formats

- Binary format (`.bin`) compatible with MediaPipe Tasks GenAI
- Int4 quantization recommended for mobile devices
- Tested with Gemma 2B models

## Troubleshooting

### CocoaPods Issues

If you encounter dependency issues:
```bash
pod deintegrate
pod install
```

### Model Download Fails

- Verify your model URL is accessible
- Check network connectivity
- Ensure sufficient storage space (models can be 1-2 GB)

### Build Errors

- Make sure you opened `.xcworkspace`, not `.xcodeproj`
- Clean build folder: `Cmd + Shift + K`
- Verify iOS deployment target is set to 17.0+

## Privacy

- All model inference happens on-device
- No data is sent to external servers
- Model files are stored locally in the app's sandbox

## Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues:** Found a bug or have a feature request? [Open an issue](../../issues/new)
2. **Submit Pull Requests:**
   - Fork the repository
   - Create a feature branch (`git checkout -b feature/amazing-feature`)
   - Commit your changes (`git commit -m 'Add amazing feature'`)
   - Push to the branch (`git push origin feature/amazing-feature`)
   - Open a Pull Request

Please ensure your code follows the existing style and includes appropriate tests.

## License

MIT License

Copyright (c) 2024 Armando Picon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

**The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.**

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

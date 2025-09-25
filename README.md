# Simple Tuner 🎸

A high-precision, multi-platform guitar tuner built with Flutter and a high‑performance native C++ audio engine.

• Accurate to 0.5 cents • Real-time FFT analysis • Smooth LED guidance • Works on Android, iOS, Windows, Linux, macOS, and Web

## Features

- High precision: ±0.5 cents accuracy
- Real-time analysis: 60 FPS LED feedback for smooth tuning
- Visual guidance: 20-LED arc, color-coded for flat/in‑tune/sharp
- Customizable settings: A4 frequency (430–450 Hz), per‑string targets
- Standard tuning included: E A D G B E
- Optimized native audio: C++ iterative radix‑2 FFT via Dart FFI
- Clean architecture: Domain-driven design, BLoC state management
- Dark theme: Comfortable, musician-friendly UI

## How it works

- Native engine (C++): The audio processor performs an optimized iterative radix‑2 Cooley–Tukey FFT with a Hann window and bit‑reversal permutation. It searches the guitar range (≈80–400 Hz) to detect the fundamental frequency and computes cents offset relative to the nearest string target.
- Dart/FFI: The Flutter app communicates with the native library through stable FFI structures and function bindings. The public Dart API remains unchanged while the native path is optimized for performance.

## Project structure

- lib/ … Flutter app (DI, BLoC, UI, domain/data layers)
- native/ … C++ audio engine (CMake project, shared library built per platform)
- android/ … Android app config and NDK/CMake integration
- ios/ … iOS app configuration
- web/ … Web entry files
- deployment/ … Dockerfiles and scripts for Web hosting and Android APK builds
- test/ … Unit tests for core logic

## Getting started

Prerequisites
- Flutter SDK (3.24.x or compatible)
- For Android builds: Android SDK, NDK 25.1.8937393, CMake 3.18.1 (already configured in android/app/build.gradle)
- For iOS builds: Xcode with command line tools
- For desktop: platform toolchain (Clang/GCC/MSVC), and for Linux ALSA headers for native build

Install dependencies
- flutter pub get

Run on a connected device or emulator
- flutter devices
- flutter run

Stop the app
- q in the Flutter console or Ctrl+C

## Running on Android (device)

1) Enable developer options and USB debugging on your phone.
2) Connect via USB, accept the RSA prompt.
3) Verify the device appears:
   - flutter doctor
   - flutter devices
4) Run the app:
   - flutter run -d <device_id>

Microphone permission
- The app requests RECORD_AUDIO at runtime. Ensure you grant it. If you deny it, you can enable it in Android Settings > Apps > Simple Tuner > Permissions.

Build a release APK (local)
- flutter build apk --release --split-per-abi
- Output is under build/app/outputs/apk/release/

## Build Android APKs inside Docker (no Android SDK on host)

A script builds the release APKs inside a container and exports them to an apk/ folder at the project root.

Prerequisites
- Docker installed and running (Linux/macOS/Windows with WSL2)

Command
- bash deployment/build_apk_in_docker.sh

What the script does
- Builds a Docker image pinned to Flutter 3.24.4
- Installs Android SDK Build-Tools 34.0.0, CMake 3.18.1, and NDK 25.1.8937393 (matching android/app/build.gradle)
- Runs flutter pub get and then flutter build apk --release --split-per-abi inside the container
- Copies all generated release APKs to ./apk/ with a timestamp prefix (YYYYMMDD-HHMMSS)

Expected outputs
- ./apk/20250101-130501-app-arm64-v8a-release.apk
- ./apk/20250101-130501-app-armeabi-v7a-release.apk
- ./apk/20250101-130501-app-x86_64-release.apk

Tips
- You can re-run the script anytime; it rebuilds the image if needed and writes new timestamped APKs.

## Web build and containerized hosting

A multi-stage Dockerfile is provided to build the Flutter Web app and serve it with Nginx.

Build the image
- docker build -f deployment/Dockerfile -t simple-tuner-web .

Run the container
- docker run --rm -p 8080:80 simple-tuner-web
- Open http://localhost:8080

Helper scripts
- deployment/run_container.sh and deployment/stop_container.sh are provided for convenience.

## Configuration and tuning

- A4 frequency: configurable (default 440 Hz)
- Tolerance: tuning tolerance in cents (default ±5 cents)
- Minimum amplitude: noise gate to ignore very quiet input
- Strings: standard 6-string guitar targets are preconfigured; custom strings can be set in code

## Troubleshooting

- Android SDK/NDK/CMake not found
  - Ensure Android Studio SDK components match android/app/build.gradle
  - Or use the Docker APK build script to avoid local NDK/CMake setup

- Device not detected (Android)
  - Check USB cable, enable USB debugging, run adb devices, accept RSA prompt

- Microphone not working
  - Grant microphone permission; check no other app is monopolizing the mic

- Unsupported ABI
  - The Android build includes arm64-v8a, armeabi-v7a, and x86_64. Make sure your device matches one of these.

## License

This project is licensed under the MIT License. See LICENSE for details.

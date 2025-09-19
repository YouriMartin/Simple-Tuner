# Simple Tuner 🎸

A high-precision, multiplatform guitar tuner application built with Flutter and optimized C++ audio processing.

## Features ✨

- **High Precision**: Accurate to 0.5 cents for professional tuning
- **Real-time Analysis**: Instant frequency detection with 60 FPS LED feedback
- **Visual Feedback**: 20 LEDs arranged in an arc with color-coded tuning guidance
- **Customizable Settings**: Adjust A4 frequency (430-450 Hz) and individual string tunings
- **Standard Tuning**: Pre-configured for standard guitar tuning (E-A-D-G-B-E)
- **Clean Architecture**: Domain-driven design with BLoC state management
- **Multiplatform**: Supports Android, iOS, Windows, Linux, and macOS
- **Optimized Audio**: C++ FFI for ultra-fast audio processing
- **Dark Theme**: Modern, musician-friendly interface

## Architecture 🏗️

This project follows **Clean Architecture** principles with clear separation of concerns:
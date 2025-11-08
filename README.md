# Video Player Pro 🎬

A beautiful, feature-rich Flutter video player app with modern UI and excellent performance.

## ✨ Features

- 🎥 **Pick & Play Videos** - Select any video from your device
- 🎨 **Modern UI** - Beautiful gradient design with smooth animations
- 📱 **Responsive** - Works perfectly on all screen sizes
- 🔄 **Recent Videos** - Quick access to previously played videos
- 🎬 **Full Controls** - Play, pause, seek, volume, and fullscreen
- 👆 **Gesture Controls** - Swipe for volume & brightness, double-tap to skip
- ⚡ **Playback Speed** - Adjust speed from 0.25x to 2.0x
- 💾 **Persistent History** - Remembers your recent videos
- 🎭 **Smooth Animations** - Delightful transitions and effects
- 🌙 **Dark Theme** - Easy on the eyes
- 🔒 **Screen Wake Lock** - Prevents screen from sleeping during playback

## 📦 Packages Used

### Core Functionality
- **video_player** (^2.9.2) - Video playback engine
- **chewie** (^1.8.5) - Advanced video player UI
- **file_picker** (^8.1.6) - File selection
- **permission_handler** (^11.3.1) - Storage permissions

### State Management & Storage
- **provider** (^6.1.2) - State management
- **shared_preferences** (^2.3.3) - Local data persistence
- **path_provider** (^2.1.5) - File system paths

### UI Enhancement
- **flutter_animate** (^4.5.0) - Smooth animations
- **google_fonts** (^6.2.1) - Beautiful typography
- **shimmer** (^3.0.0) - Loading effects

### Advanced Controls
- **screen_brightness** (^1.0.1) - Brightness control
- **volume_controller** (^2.0.7) - Volume control
- **wakelock_plus** (^1.2.8) - Screen wake lock

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── providers/
│   └── video_provider.dart           # Video state management
├── screens/
│   └── home_screen.dart              # Main screen
├── widgets/
│   ├── video_player_widget.dart      # Video player component
│   ├── empty_state_widget.dart       # Empty state UI
│   └── recent_videos_widget.dart     # Recent videos list
└── services/
    └── file_picker_service.dart      # File picking logic
```

## 🚀 Getting Started

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Run the app:**
```bash
flutter run
```

## 🎯 Usage

### Basic Controls
1. Launch the app
2. Tap the **"Pick Video"** floating button
3. Grant storage permissions if prompted
4. Select a video from your device
5. Video opens in **fullscreen player** automatically
6. Video plays with full gesture controls
7. Tap **back button** to return to home
8. Tap the **history icon** to view recent videos and quick play

### Gesture Controls
- **Swipe Up/Down (Left Side)** - Adjust brightness
- **Swipe Up/Down (Right Side)** - Adjust volume
- **Double Tap Left** - Rewind 10 seconds
- **Double Tap Right** - Forward 10 seconds
- **Single Tap** - Show/hide controls
- **Tap Speed Icon** - Change playback speed (0.25x - 2.0x)

## 🎨 UI Highlights

- **Gradient Background** - Deep purple to black gradient
- **Animated Elements** - Fade, scale, and slide animations
- **Glass Morphism** - Frosted glass effect on cards
- **Custom Icons** - Themed icons throughout
- **Responsive Layout** - Adapts to any screen size

## 🔧 Performance Optimizations

- **Provider Pattern** - Efficient state management
- **Lazy Loading** - Videos load only when needed
- **Memory Management** - Proper disposal of controllers
- **Cached Preferences** - Fast access to recent videos
- **Optimized Animations** - Smooth 60fps animations

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🔐 Permissions

### Android
- Storage access for video files
- Media access (Android 13+)

### iOS
- Photo library access
- Camera access (optional)

## 🎓 Code Quality

- Clean architecture with separation of concerns
- Provider pattern for state management
- Reusable widgets and services
- Proper error handling
- Memory leak prevention
- Type-safe code

## 🤝 Contributing

Feel free to fork and improve this project!

## 📄 License

This project is open source and available under the MIT License.

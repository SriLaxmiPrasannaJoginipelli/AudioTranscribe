# 🎙️ AudioTranscribe

A SwiftUI iOS app for recording audio in 30-second segments with real-time transcription using OpenAI Whisper or Apple's native speech recognition.

## 📱 Screenshots

| Recording Interface | Session List | Transcription View |
|---------------------|--------------|--------------------|
| ![Recording](https://github.com/user-attachments/assets/ac0af343-0b61-43c6-8040-430bff5f7270) | ![79E0A382-E1A7-4BB0-A749-18A6F645685E_1_102_o](https://github.com/user-attachments/assets/41b75294-b28e-469f-9f99-f36de7f5af42) | ![75D20BB4-8DA5-4F5F-93F0-C8E20C0760C1_1_102_o](https://github.com/user-attachments/assets/f376ff30-799a-4fd1-9c2b-e9d798268e42) |

----

| Microphone Permission Alert | Audio Disconnected Alert| Low Diskspace Alert |
|---------------------|--------------|--------------------|
| ![C8FF5BDF-BF00-445D-9C70-9ADC6FB74CD7_1_102_o](https://github.com/user-attachments/assets/5ece17f2-f310-4533-95a9-362e6892b957) | ![675279BF-E272-4AFD-82D2-B83766F159D2_1_102_o](https://github.com/user-attachments/assets/2df017ae-0efa-4112-bc78-d529885c8021) | ![2C73AD88-CBDC-4A60-9566-42BAF7707118_1_102_o](https://github.com/user-attachments/assets/9c68c6ca-007b-42e0-8712-be20e96ab4fb) |


## ✨ Key Features

### 🎤 Recording
- 30-second audio segments with automatic re-encoding to `.m4a`
- Real-time waveform visualization with dB power levels
- Robust interruption handling for audio route changes

### 📝 Transcription
- Dual-engine transcription (OpenAI Whisper API + Apple Speech fallback)
- Smart retry mechanism with exponential backoff
- Multi-language support with user-selectable options

### 💾 Data Management
- Persistent storage with SwiftData
- Indexed relationships for performance
- Advanced search by date/time

## 🚀 Quick Start

### Requirements
- iOS 18.5+
- Xcode 15+
- Physical device (microphone required)

### Installation
1. Clone the repository
2. Add your OpenAI API key (`sk-xxxxxx`) from [platform.openai.com](https://platform.openai.com/api-keys)
3. Build and run on a physical device

## 🏗️ Architecture

### MVVM + Service Layer
- **ViewModels**: `@MainActor` annotated for thread safety
- **Services**:
  - `AudioRecorderService`: Handles audio recording
  - `TranscriptionService`: Manages transcription logic
  - `TranscriptionQueue`: Coordinates ordered execution

### Core Technologies
- `AVAudioEngine` for real-time audio processing
- Swift Concurrency with `Task` and `@MainActor`
- SwiftData for persistence

## 🔧 Technical Highlights

### Audio System
- 30-second `.caf` segments converted to `.m4a`
- Duplicate detection
- Handles 1000+ sessions and 10,000+ segments

### Transcription Flow

The app implements a sophisticated transcription system with exponential backoff:

```
OpenAI Whisper API Attempts:
├── Attempt 1 failed. Retrying in 1.0s...
├── Attempt 2 failed. Retrying in 2.0s...
├── Attempt 3 failed. Retrying in 4.0s...
├── Attempt 4 failed. Retrying in 8.0s...
├── Attempt 5 failed. Fallback triggered after 5 failures
└── Apple Speech Recognition (Fallback)
```

## Language Support

### Supported Features
- **Primary Language**: English (en) - Default selection
- **Multi-language Support**: Configurable via TranscriptionService
- **User Selection**: Choose from available languages in settings

<img src="https://github.com/user-attachments/assets/bb0707f7-ffd4-4522-9e28-ba42528f838e" width="300" alt="Language selection interface">

### Implementation Details
- Dynamic language switching during recording sessions
- Locale-aware transcription processing
- Fallback to device language when unspecified

## Data Model

### SwiftData Schema

```swift
RecordingSession
├── id: UUID
├── title: String
├── createdAt: Date
├── language: String = "en"
└── segments: [TranscriptionSegment]

TranscriptionSegment
├── id: UUID
├── audioFilePath: String
├── transcriptionText: String?
├── status: TranscriptionStatus
├── retryCount: Int
├── transcriptionMethod: TranscriptionMethod
└── session: RecordingSession
```

### Performance Optimizations
- Indexed sort descriptors for fast filtering
- Lazy loading and relationships (`@Relationship`)
- Background context for heavy operations
- Efficient memory management for large datasets

## Testing Coverage

### Unit Tests
- Validate `RecordingSession` and `TranscriptionSegment` creation and state transitions
- Verify fallback logic and retry counters with exponential backoff

### Integration Tests
- Audio start/stop with mic permissions and disk space checks
- Transcription API interaction with retry mechanism
- Device disconnection and reconnection scenarios

###  Edge Case Tests
- Mic denied, route change, disk full scenarios
- Network unavailable, app interruptions, background limitations
- Bluetooth device connection/disconnection during recording

### Performance Tests
- Simulate processing 10,000+ segments and verify SwiftData responsiveness
- Memory usage profiling during extended recording sessions
- Battery impact analysis

## Advanced Features

### Real-Time Audio Visualization
- Live waveform rendering using `AVAudioMixerNode` buffer metering
- Dynamic scaling with dB power level visualization
- Smooth 60fps animation with Core Animation

### Intelligent Search
- Filter sessions by time ranges 


## Known Issues & Limitations

| Issue | Description | Impact | Status |
|-------|-------------|--------|--------|
| Mic Permission | App requires microphone access for recording | High | By design |
| Network Dependency | Whisper API needs internet; segments queued offline | Medium | Handled |
| Battery Usage | Continuous recording increases battery drain | Medium | Monitoring added |
| Background Limits | iOS may suspend background tasks after 30s | Low | Planned optimization |
| Local Whisper | Offline transcription not yet supported | Low | Roadmap item |


## Development

### Project Structure
```
AudioTranscribe/
├── Models/           # SwiftData models
├── Services/         # Audio & Transcription services
├── ViewModels/       # MVVM view models
├── Views/           # SwiftUI views
├── Utils/           # Helper utilities
└── Tests/           # Unit & integration tests
```

---
**Built with ❤️ using SwiftUI, SwiftData, and OpenAI Whisper**

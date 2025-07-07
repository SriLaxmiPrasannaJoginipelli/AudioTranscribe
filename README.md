# 🎙️ AudioTranscribe

A SwiftUI iOS app for recording audio in 30-second segments with real-time transcription using OpenAI Whisper or Apple's native speech recognition. Features live waveform visualization and persistent storage with SwiftData.

![E3C329A9-902D-4BCE-BA8C-8D9C6C94202F_1_102_o](https://github.com/user-attachments/assets/ac0af343-0b61-43c6-8040-430bff5f7270)

## Features

- **Smart Recording**: 30-second audio segments with automatic re-encoding to `.m4a`
- **Dual Transcription**: OpenAI Whisper API with Apple Speech fallback after 5 failures
- **Live Visualization**: Real-time waveform rendering with dB power levels
- **Persistent Storage**: SwiftData for sessions and segments with indexed relationships
- **Supports Different Languages**: User can select the language they wanna transcribe to from the list available.
- **Advanced Search**: Filter by date
- **Robust Interruption Handling**: Graceful audio route changes, device disconnections, and app interruptions
- **Permission Management**: Comprehensive microphone permission handling

![C8FF5BDF-BF00-445D-9C70-9ADC6FB74CD7_1_102_o](https://github.com/user-attachments/assets/9e992338-dc62-4265-8368-ee918232dfe5)

![675279BF-E272-4AFD-82D2-B83766F159D2_1_102_o](https://github.com/user-attachments/assets/5d4daf39-f878-4ca1-9fdd-972eaa9370e4)

## Quick Start

### Requirements
- iOS 18.5
- Xcode 15+
- Physical device (microphone required)

### Setup
1. Clone the repository
2. Replace `sk-xxxxxx` with your actual OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys)
4. Build and run on a physical device

## Architecture

### Clean MVVM + Service-Oriented Design

The app is built using a modular **MVVM architecture** with clean separation of concerns:

- **RecordingViewModel**: Controls state and UI logic with `@MainActor` annotations
- **AudioRecorderService**: Handles audio recording, segmentation, and interruptions
- **TranscriptionService**: Manages transcription logic with retry/fallback flow
- **TranscriptionQueue**: Coordinates ordered, concurrent-safe transcription execution
- **SwiftData Models**: Persist sessions, segments, and transcriptions

**Concurrency** is handled with `Task`, `MainActor`, and `@MainActor` annotations to ensure thread safety. Audio-related operations run in background threads, with UI updates dispatched to the main thread.

### Key Technologies
- `AVAudioEngine` + `AVAudioMixerNode` for real-time audio processing and metering
- `Task` and `@MainActor` for Swift Concurrency
- Duplicate detection
- Indexed SwiftData relationships for performance optimization

## Audio System Design

### Recording Approach

- Uses `AVAudioEngine` + `AVAudioMixerNode` for real-time audio processing and metering
- Audio is recorded in 30-second `.caf` segments and re-encoded to `.m4a` format asynchronously
- Duplicate detection is implemented
- Support for 1000+ sessions and 10,000+ segments with lazy loading

### Audio Route & Interruptions

- Listens to `AVAudioSession.routeChangeNotification` and `interruptionNotification`
- **Device Disconnection Handling**: Bluetooth headsets, wired headphones, external microphones
- **Microphone Permission Management**: Complete permission flow with user alerts
- On headset/mic disconnection:
  - Gracefully stops current segment
  - Alerts the user with contextual messages
  - Automatically restarts recording when device reconnects

![675279BF-E272-4AFD-82D2-B83766F159D2_1_102_o](https://github.com/user-attachments/assets/d23359b1-7169-4615-875f-5cfa2637142a)

![E5E87EDE-C986-4626-B49D-6F3F82217CDF_1_102_o](https://github.com/user-attachments/assets/b70ae8f1-0288-4dba-b555-f06904ba5c0d)

## Transcription System

### Robust Retry & Fallback Mechanism

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

### Language Support
- **Primary**: English (en) - ReadMe selected language
- **API Configuration**: Configurable language settings in TranscriptionService

![81F655EF-0B34-4F68-AFB4-4B364E88D3F2_1_102_o](https://github.com/user-attachments/assets/bb0707f7-ffd4-4522-9e28-ba42528f838e)

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

![Data Model Diagram](docs/data-model.png)

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

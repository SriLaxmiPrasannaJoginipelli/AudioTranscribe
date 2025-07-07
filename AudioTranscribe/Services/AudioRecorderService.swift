//
//  AudioRecorderService.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//
import AVFoundation
import Combine

protocol AudioRecorderDelegate: AnyObject {
    func didFinishSegment(_ url: URL)
    func updateLevel(_ level: Float)
}

final class AudioRecorderService: NSObject, ObservableObject {
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var file: AVAudioFile?
    private let segmentDuration: TimeInterval = 30
    private(set) var recordingURL: URL?
    private var recordingStartTime: Date?
    private var segmentTimer: Timer?
    private var lastSegmentStartTime: Date?
    private var currentSessionId: UUID = UUID() 
    
    @Published var isRecording = false
    @Published var showMicPermissionAlert = false
    @Published var showDeviceDisconnectedAlert = false
    weak var delegate: AudioRecorderDelegate?
    
    var isTesting = false
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Recording Control
    
    @MainActor
    func startRecording() async throws -> Bool {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .granted:
            break // continue
        case .denied:
            print("Microphone permission denied.")
            self.showMicPermissionAlert = true
            return false
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            
            if !granted {
                print("Microphone permission not granted by user.")
                self.showMicPermissionAlert = true
                return false
            }
        }
        
        // Clean up any previous session data
        cleanupPreviousSession()
        
        // Generate new session ID
        currentSessionId = UUID()
        
        stopRecording()
        recordingStartTime = Date()
        lastSegmentStartTime = Date()
        
        try startNewSegment()
        
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { [weak self] _ in
            Task{
                await self?.finalizeSegment()
            }
        }
        
        try configureAudioSession()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        return true
    }
    
    func stopRecording() {
        audioEngine?.stop()
        mixerNode?.removeTap(onBus: 0)
        file = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        segmentTimer?.invalidate()
        segmentTimer = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        guard let rawURL = recordingURL else {
            // Clear any persisted state since we have no current recording
            UserDefaults.standard.removeObject(forKey: "PendingRecordingURL")
            UserDefaults.standard.removeObject(forKey: "PendingSessionID")
            return
        }
        
        // Clear the current recording URL to prevent reuse
        recordingURL = nil
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                let duration = try await getAudioDuration(url: rawURL)
                if duration < 1 {
                    print("Ignoring short segment (<1s)")
                    // Clean up the file
                    try? FileManager.default.removeItem(at: rawURL)
                    return
                }
                
                let cleanURL = try await reencodeToM4A(rawURL)
                await MainActor.run {
                    self.delegate?.didFinishSegment(cleanURL)
                }
                
                // Clean up the original file
                try? FileManager.default.removeItem(at: rawURL)
                
            } catch {
                print("Finalization failed: \(error.localizedDescription)")
                // Clean up the file even on error
                try? FileManager.default.removeItem(at: rawURL)
            }
        }
        
        // Clear persisted state after stopping
        UserDefaults.standard.removeObject(forKey: "PendingRecordingURL")
        UserDefaults.standard.removeObject(forKey: "PendingSessionID")
    }
    
    // MARK: - Segmentation Logic
    
    @MainActor
    func finalizeSegment() {
        mixerNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine?.reset()

        let finishedCAFURL = recordingURL
        let sessionId = currentSessionId
        recordingURL = nil
        file = nil

        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)

                if let finishedCAFURL = finishedCAFURL {
                    let duration = try await self.getAudioDuration(url: finishedCAFURL)
                    if duration >= 1 {
                        let cleanM4AURL = try await self.reencodeToM4A(finishedCAFURL)
                        
                        // Only send to delegate if this is still the current session
                        await MainActor.run {
                            if sessionId == self.currentSessionId {
                                self.delegate?.didFinishSegment(cleanM4AURL)
                            }
                        }
                    } else {
                        print("Discarded segment: too short")
                    }
                    
                    // Clean up the original CAF file
                    try? FileManager.default.removeItem(at: finishedCAFURL)
                }

                // Only start new segment if still in the same session
                if sessionId == self.currentSessionId && self.isRecording {
                    try await MainActor.run {
                        try self.startNewSegment()
                    }
                }

            } catch {
                print("finalizeSegment error: \(error)")
                // Only restart if still in the same session
                if sessionId == self.currentSessionId && self.isRecording {
                    Task {
                        _ = try? await self.startRecording()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func startNewSegment() throws {
        let newURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("segment-\(currentSessionId.uuidString.prefix(6))-\(UUID().uuidString.prefix(6)).caf")
        
        recordingURL = newURL
        lastSegmentStartTime = Date()
        
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        
        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.attach(mixerNode)
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: inputFormat)
        
        file = try AVAudioFile(forWriting: newURL, settings: inputFormat.settings)
        
        try audioEngine.start()
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            try? self.file?.write(from: buffer)
            
            // Real-time level metering
            buffer.frameLength = 1024
            let channelData = buffer.floatChannelData?[0]
            let frameCount = Int(buffer.frameLength)
            var rms: Float = 0
            
            if let channelData = channelData {
                for i in 0..<frameCount {
                    rms += channelData[i] * channelData[i]
                }
                rms = sqrt(rms / Float(frameCount))
                let avgPower = 20 * log10(rms)
                DispatchQueue.main.async {
                    self.delegate?.updateLevel(avgPower)
                }
            }
        }
        
        // Persist the current state
        persistCurrentRecordingState()
    }
    
    // MARK: - Utility
    
    func getAudioDuration(url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
    
    private func reencodeToM4A(_ inputURL: URL) async throws -> URL {
        let asset = AVAsset(url: inputURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Reencode", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."])
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cleaned-\(UUID().uuidString.prefix(6)).m4a")
        
        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        return try await withCheckedThrowingContinuation { continuation in
            exporter.exportAsynchronously {
                if let error = exporter.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: outputURL)
                }
            }
        }
    }
    
    // MARK: - Audio Session
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }
    
    // MARK: - Audio Route + Interruption
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Get details about what was disconnected
            if let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                let disconnectedInputs = previousRoute.inputs
                let disconnectedOutputs = previousRoute.outputs
                
                // Check if it was an important audio device
                let wasImportantDevice = disconnectedInputs.contains { input in
                    input.portType == .bluetoothHFP ||
                    input.portType == .headsetMic ||
                    input.portType == .bluetoothA2DP
                } || disconnectedOutputs.contains { output in
                    output.portType == .bluetoothHFP ||
                    output.portType == .headphones ||
                    output.portType == .bluetoothA2DP
                }
                
                if wasImportantDevice {
                    print("Important audio device disconnected - stopping recording")
                    stopRecording()
                    
                    DispatchQueue.main.async {
                        self.showDeviceDisconnectedAlert = true
                    }
                }
            }
            
        case .noSuitableRouteForCategory:
            print("No suitable audio route available")
            stopRecording()
            
            DispatchQueue.main.async {
                self.showDeviceDisconnectedAlert = true
            }
            
        default:
            print("Audio route change: \(reason.rawValue)")
        }
    }
    
    @MainActor @objc private func handleInterruption(notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            print("Audio interruption began")
            stopRecording()
        } else {
            print("Audio interruption ended")
            Task{
                try? await startRecording()
            }
        }
    }
    
    // MARK: - Session Management
    
    private func cleanupPreviousSession() {
        // Remove any pending recordings from previous sessions
        UserDefaults.standard.removeObject(forKey: "PendingRecordingURL")
        UserDefaults.standard.removeObject(forKey: "PendingSessionID")
        
        // Clean up any temporary files from previous sessions
        cleanupTemporaryFiles()
    }
    
    private func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("segment-") || fileName.hasPrefix("cleaned-") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Error cleaning temporary files: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    func persistCurrentRecordingState() {
        if let url = recordingURL {
            UserDefaults.standard.set(url.path, forKey: "PendingRecordingURL")
            UserDefaults.standard.set(currentSessionId.uuidString, forKey: "PendingSessionID")
        }
    }

    func recoverIfNeeded() {
        guard let path = UserDefaults.standard.string(forKey: "PendingRecordingURL"),
              let sessionIdString = UserDefaults.standard.string(forKey: "PendingSessionID"),
              let sessionId = UUID(uuidString: sessionIdString),
              FileManager.default.fileExists(atPath: path) else {
            // Clean up invalid state
            UserDefaults.standard.removeObject(forKey: "PendingRecordingURL")
            UserDefaults.standard.removeObject(forKey: "PendingSessionID")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        Task {
            do {
                let duration = try await getAudioDuration(url: url)
                if duration > 1 {
                    // Process the recovered file properly
                    let cleanURL = try await reencodeToM4A(url)
                    await MainActor.run {
                        self.delegate?.didFinishSegment(cleanURL)
                    }
                    
                    // Clean up the original file
                    try? FileManager.default.removeItem(at: url)
                } else {
                    print("Discarded recovered segment: too short")
                    try? FileManager.default.removeItem(at: url)
                }
            } catch {
                print("Error recovering segment: \(error)")
                try? FileManager.default.removeItem(at: url)
            }
            
            // Clean up the persisted state
            UserDefaults.standard.removeObject(forKey: "PendingRecordingURL")
            UserDefaults.standard.removeObject(forKey: "PendingSessionID")
        }
    }
}

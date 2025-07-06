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
    
    
    
    @Published var isRecording = false
    weak var delegate: AudioRecorderDelegate?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Recording Control
    
    @MainActor
    func startRecording() throws {
        stopRecording()
        recordingStartTime = Date()
        lastSegmentStartTime = Date()
        
        try startNewSegment()
        
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { [weak self] _ in
            self?.finalizeSegment()
        }
        
        try configureAudioSession()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
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
        
        guard let rawURL = recordingURL else { return }
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                let duration = try await getAudioDuration(url: rawURL)
                if duration < 1 {
                    print("Ignoring short segment (<1s)")
                    return
                }
                
                let cleanURL = try await reencodeToM4A(rawURL)
                await MainActor.run {
                    self.delegate?.didFinishSegment(cleanURL)
                }
                
            } catch {
                print("Finalization failed: \(error.localizedDescription)")
            }
        }
        
    }
    
    
    
    
    // MARK: - Segmentation Logic
    
    
    private func reencodeTrimmedM4A(from url: URL, startOffset: Double, duration: Double) async throws -> URL {
        let asset = AVAsset(url: url)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Reencode", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."])
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cleaned-\(UUID().uuidString.prefix(6)).m4a")
        
        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        
        let timescale: CMTimeScale = 600
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: startOffset, preferredTimescale: timescale),
            duration: CMTime(seconds: duration, preferredTimescale: timescale)
        )
        
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
    @MainActor
    func finalizeSegment() {
        // Stop tap and engine cleanly
        mixerNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine?.reset()
        
        let finishedCAFURL = recordingURL
        recordingURL = nil
        file = nil
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                
                if let finishedCAFURL = finishedCAFURL {
                    let duration = try await getAudioDuration(url: finishedCAFURL)
                    if duration >= 1 {
                        let cleanM4AURL = try await reencodeToM4A(finishedCAFURL)
                        await MainActor.run {
                            self.delegate?.didFinishSegment(cleanM4AURL)
                        }
                    } else {
                        print("Discarded segment: too short")
                    }
                }
                
                try await self.startNewSegment()
                
            } catch {
                print("finalizeSegment error: \(error)")
                try? await MainActor.run { try self.startRecording() }
            }
        }
    }
    
    
    
    
    @MainActor
    private func startNewSegment() throws {
        let newURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("segment-\(UUID().uuidString.prefix(6)).caf")
        
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
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable else { return }
        
        print("Audio route changed (e.g. headphones unplugged)")
    }
    
    @MainActor @objc private func handleInterruption(notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            print("Audio interruption began")
            stopRecording()
        } else {
            print("Audio interruption ended")
            try? startRecording()
        }
    }
}

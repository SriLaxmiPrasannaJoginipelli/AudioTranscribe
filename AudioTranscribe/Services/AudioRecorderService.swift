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
}

final class AudioRecorderService: NSObject, ObservableObject {
    // MARK: - Properties

    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var file: AVAudioFile?
    private let segmentDuration: TimeInterval = 30
    private(set) var recordingURL: URL?

    @Published var isRecording = false
    weak var delegate: AudioRecorderDelegate?

    // MARK: - Lifecycle

    override init() {
        super.init()
        setupNotifications()
    }

    // MARK: - Recording Control

    func startRecording() throws {
        stopRecording()

        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()

        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.attach(mixerNode)
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: inputFormat)

        print("Using audio format: \(inputFormat)")

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString.prefix(6)).caf")
        recordingURL = url

        file = try AVAudioFile(forWriting: url, settings: inputFormat.settings)

        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            try? self?.file?.write(from: buffer)
        }

        try configureAudioSession()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        mixerNode?.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false)

        DispatchQueue.main.async {
            self.isRecording = false
        }

        guard let rawURL = recordingURL else { return }

        Task {
            do {
                let cleanURL = try await reencodeToM4A(rawURL)
                let duration = try await getAudioDuration(url: cleanURL)

                if duration < segmentDuration {
                    await MainActor.run {
                        self.delegate?.didFinishSegment(cleanURL)
                    }
                } else {
                    let segments = try await segmentAudioFile(cleanURL)
                    for segment in segments {
                        await MainActor.run {
                            self.delegate?.didFinishSegment(segment)
                        }
                    }
                }
            } catch {
                print("Finalization failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Segmentation Logic

    func segmentAudioFile(_ url: URL) async throws -> [URL] {
        let duration = try await getAudioDuration(url: url)
        var segments: [URL] = []
        var start: Double = 0

        while start < duration {
            let end = min(start + segmentDuration, duration)
            let segmentURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("segment-\(UUID().uuidString.prefix(6)).m4a")

            try await trimAudio(sourceURL: url, start: start, end: end, destinationURL: segmentURL)
            segments.append(segmentURL)
            start = end
        }

        return segments
    }

    func trimAudio(sourceURL: URL, start: Double, end: Double, destinationURL: URL) async throws {
        let asset = AVAsset(url: sourceURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create exporter"])
        }

        exporter.outputURL = destinationURL
        exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            end: CMTime(seconds: end, preferredTimescale: 600)
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exporter.exportAsynchronously {
                if let error = exporter.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
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

    @objc private func handleInterruption(notification: Notification) {
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

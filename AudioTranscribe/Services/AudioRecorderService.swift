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
    private var timer: Timer?

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
        stopRecording() // ensure fresh session

        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()

        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.attach(mixerNode)
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: format)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString.prefix(6)).m4a")
        recordingURL = url
        file = try AVAudioFile(forWriting: url, settings: format.settings)

        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
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
        audioEngine?.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false)

        DispatchQueue.main.async {
            self.isRecording = false
        }

        guard let url = recordingURL else { return }

        Task {
            let duration = try await getAudioDuration(url: url)

            if duration < segmentDuration {
                await MainActor.run {
                    self.delegate?.didFinishSegment(url)
                }
            } else {
                do {
                    let segments = try await segmentAudioFile(url)
                    for segment in segments {
                        await MainActor.run {
                            self.delegate?.didFinishSegment(segment)
                        }
                    }
                } catch {
                    print("Segmenting failed: \(error)")
                }
            }
        }
    }

    // MARK: - Segmentation Logic

    func segmentAudioFile(_ url: URL) async throws -> [URL] {
        let duration = try await getAudioDuration(url: url)
        var segmentURLs: [URL] = []
        var startTime = 0.0

        while startTime < duration {
            let endTime = min(startTime + segmentDuration, duration)
            let segmentURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("segment-\(UUID().uuidString.prefix(6)).m4a")

            try await trimAudio(sourceURL: url, start: startTime, end: endTime, destinationURL: segmentURL)
            segmentURLs.append(segmentURL)
            startTime = endTime
        }

        return segmentURLs
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


    func getAudioDuration(url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }

    // MARK: - Audio Session

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
        try session.setActive(true)
    }

    // MARK: - Audio Route + Interruption

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        print("Headphones unplugged")
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        if type == AVAudioSession.InterruptionType.began.rawValue {
            stopRecording()
        } else {
            try? startRecording()
        }
    }
}


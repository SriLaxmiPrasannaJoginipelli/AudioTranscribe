//
//  AudioRecorderService.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import AVFoundation
import Combine

final class AudioRecorderService: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var file: AVAudioFile?
    private var timer: Timer?
    private let queue = TranscriptionQueue()
    
    private var segmentIndex = 0
    private let segmentDuration: TimeInterval = 30
    private var currentSegmentStartTime: Date = Date()

    private(set) var recordingURL: URL?
    @Published var isRecording = false

    override init() {
        super.init()
        setupNotifications()
    }

    func startRecording() throws {
        stopRecording()
        recordingURL = URL.tempRecordingURL(segmentIndex: segmentIndex)
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()

        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.attach(mixerNode)
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: format)

        file = try AVAudioFile(forWriting: recordingURL!, settings: format.settings)
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            try? self?.file?.write(from: buffer)
        }

        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)
        try audioEngine.start()

        currentSegmentStartTime = Date()
        segmentIndex += 1
        DispatchQueue.main.async {
            self.isRecording = true
        }

        timer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { [weak self] _ in
            Task { await self?.rotateSegment() }
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false)
        timer?.invalidate()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    private func rotateSegment() async {
        stopRecording()
        if let currentURL = recordingURL {
            await queue.enqueue(currentURL)
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        try? startRecording()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else { return }
        if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
            print("🔌 Headphones unplugged")
        }
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


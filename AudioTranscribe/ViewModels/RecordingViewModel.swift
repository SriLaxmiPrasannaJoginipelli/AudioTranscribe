//
//  RecordingViewModel.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import SwiftData

@MainActor
class RecordingViewModel: ObservableObject {
    private let context: ModelContext
    private let recorder = AudioRecorderService()
    private let queue = TranscriptionQueue()
    @Published var transcriptionMessage: String?
    @Published var transcriptionError: String?
    @Published var recordingDuration: TimeInterval = 0
    private var timer: Timer?
    @Published var currentLevel: Float = -160.0
    @Published var showMicPermissionAlert: Bool = false
    @Published var showDiskSpaceAlert = false
    @Published var showDeviceDisconnectedAlert: Bool = false

    
    static let supportedLanguages: [TranscriptionLanguage] = [
        .init(code: "en", name: "English"),
        .init(code: "es", name: "Spanish"),
        .init(code: "fr", name: "French"),
        .init(code: "de", name: "German"),
        .init(code: "it", name: "Italian"),
        .init(code: "pt", name: "Portuguese"),
        .init(code: "hi", name: "Hindi"),
        .init(code: "ja", name: "Japanese"),
        .init(code: "zh", name: "Chinese")
    ]


    @Published var isRecording = false
    @Published var selectedLanguage: TranscriptionLanguage = supportedLanguages.first!
    private var currentSession: RecordingSession?


    init(context: ModelContext) {
        self.context = context
        recorder.delegate = self
        recorder.$showMicPermissionAlert
                .receive(on: DispatchQueue.main)
                .assign(to: &$showMicPermissionAlert)
        recorder.$showDeviceDisconnectedAlert
                .receive(on: DispatchQueue.main)
                .assign(to: &$showDeviceDisconnectedAlert)
    }


    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        Task {
            do {
                guard hasSufficientDiskSpace() else {
                    print("Not enough disk space to record audio.")
                    showDiskSpaceAlert = true
                    return
                }

                let started = try await recorder.startRecording()
                if started {
                    currentSession = RecordingSession(title: "Session \(Date().formatted(.dateTime.hour().minute()))")
                    context.insert(currentSession!)
                    isRecording = true
                    startTimer()
                }
            } catch {
                print("Failed to start: \(error)")
            }
        }

    }

    func stopRecording() {
        recorder.stopRecording()
        isRecording = false
        stopTimer()
    }

    func handleSegment(_ url: URL) {
        guard let session = currentSession else { return }
        let segment = TranscriptionSegment(audioFilePath: url.path, session: session)
        session.segments.append(segment)
        context.insert(segment)

        Task {
            transcriptionMessage = "Transcribing segment..."
            do {
                print("selected language is :\(selectedLanguage.code)")
                try await queue.enqueue(segment: segment, context: context, language: selectedLanguage)
                transcriptionMessage = "Transcription complete"
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                transcriptionMessage = nil
            } catch {
                transcriptionError = "Transcription failed: \(error.localizedDescription)"
            }
        }

    }
    func handleDeviceDisconnection() {
        // Stop recording if still active
        if isRecording {
            stopRecording()
        }
        
        // Reset the alert flag
        showDeviceDisconnectedAlert = false
        
        // Reset the recorder's alert flag
        recorder.showDeviceDisconnectedAlert = false
    }
    
    private func startTimer() {
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK : Disk Storage Check
    func hasSufficientDiskSpace(thresholdInMB: Int = 50) -> Bool {
        if let freeSpace = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemFreeSize] as? NSNumber {
            let freeSpaceMB = freeSpace.doubleValue / (1024 * 1024)
            print("freeSpaceMB : \(freeSpaceMB)")
            print("thresholdInMB: \(thresholdInMB)")
            return freeSpaceMB > Double(thresholdInMB)
        }
        return false
    }


}

extension RecordingViewModel: AudioRecorderDelegate {
    func didFinishSegment(_ url: URL) {
        handleSegment(url)
    }
    func updateLevel(_ level: Float) {
        DispatchQueue.main.async {
            self.currentLevel = max(-60, level) 
        }
    }

}

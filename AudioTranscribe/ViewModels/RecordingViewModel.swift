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
    }


    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        do {
            try recorder.startRecording()
            currentSession = RecordingSession(title: "Session \(Date().formatted(.dateTime.hour().minute()))")
            context.insert(currentSession!)
            isRecording = true
        } catch {
            print("⚠️ Failed to start: \(error)")
        }
    }

    func stopRecording() {
        recorder.stopRecording()
        isRecording = false
    }

    func handleSegment(_ url: URL) {
        guard let session = currentSession else { return }
        let segment = TranscriptionSegment(audioFilePath: url.path, session: session)
        session.segments.append(segment)
        context.insert(segment)
        Task { await queue.enqueue(url) }
    }
}

extension RecordingViewModel: AudioRecorderDelegate {
    func didFinishSegment(_ url: URL) {
        handleSegment(url)
    }
}

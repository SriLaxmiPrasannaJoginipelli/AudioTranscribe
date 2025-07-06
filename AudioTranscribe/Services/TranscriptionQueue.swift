//
//  TranscriptionQueue.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation

actor TranscriptionQueue {
    private let transcriptionService = TranscriptionService()
    private let fallback = AppleSpeechFallback()
    
    private var pendingFiles: [URL] = []
    private var failureCount = 0
    private let failureThreshold = 5

    func enqueue(_ file: URL) {
        pendingFiles.append(file)
        processQueue()
    }

    private func processQueue() {
        Task {
            while !pendingFiles.isEmpty {
                let current = pendingFiles.removeFirst()
                do {
                    let result: String
                    if failureCount >= failureThreshold {
                        print("⚠️ Using Apple fallback transcription")
                        result = try await fallback.transcribe(fileURL: current)
                    } else {
                        result = try await transcriptionService.transcribeAudio(fileURL: current)
                    }
                    print("Transcription Success:\n\(result)")
                    failureCount = 0
                } catch {
                    if let transcriptionError = error as? TranscriptionError {
                        switch transcriptionError {
                        case .networkError(let message):
                            print("Network Error: \(message)")
                        case .quotaExceeded:
                            print(" Quota exceeded – check OpenAI billing.")
                        case .decodeError:
                            print("Failed to decode Whisper API response.")
                        }
                    } else {
                        print("❌ Unknown error: \(error.localizedDescription)")
                    }

                    failureCount += 1
                    let delay = pow(2.0, Double(failureCount)) // exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    pendingFiles.insert(current, at: 0) // requeue
                }
            }
        }
    }
}


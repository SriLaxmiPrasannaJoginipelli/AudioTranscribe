//
//  TranscriptionQueue.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import SwiftData

actor TranscriptionQueue {
    private var isProcessing = false
    private var queue: [(segment: TranscriptionSegment, context: ModelContext)] = []

    func enqueue(segment: TranscriptionSegment, context: ModelContext) async {
        queue.append((segment, context))
        await processNext()
    }

    private func processNext() async {
        guard !isProcessing, let (segment, context) = queue.first else { return }
        isProcessing = true

        let url = URL(fileURLWithPath: segment.audioFilePath)

        do {
            let text = try await TranscriptionService().transcribeAudio(fileURL: url)
            await MainActor.run {
                segment.transcriptionText = text
                segment.status = .completed
                do {
                    try context.save()
                } catch {
                    print("Save error: \(error)")
                }
            }
        } catch {
            await MainActor.run {
                segment.status = .failed
                segment.transcriptionText = "\(error.localizedDescription)"
            }
        }

        queue.removeFirst()
        isProcessing = false
        if !queue.isEmpty {
            await processNext()
        }
    }
}

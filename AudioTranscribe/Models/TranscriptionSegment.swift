//
//  TranscriptionSegment.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import SwiftData

enum TranscriptionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

@Model
class TranscriptionSegment {
    @Attribute(.unique) var id: UUID
    var audioFilePath: String
    var transcriptionText: String?
    var status: TranscriptionStatus
    var failureCount: Int
    var createdAt: Date

    @Relationship var session: RecordingSession?

    init(audioFilePath: String,
         status: TranscriptionStatus = .pending,
         createdAt: Date = .now,
         session: RecordingSession? = nil) {
        self.id = UUID()
        self.audioFilePath = audioFilePath
        self.status = status
        self.failureCount = 0
        self.createdAt = createdAt
        self.session = session
    }

    var audioFileURL: URL {
        return URL(fileURLWithPath: audioFilePath)
    }
}


//
//  RecordingSession.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import SwiftData

@Model
class RecordingSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var segments: [TranscriptionSegment] = []

    init(title: String = "Untitled", createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
    }
}


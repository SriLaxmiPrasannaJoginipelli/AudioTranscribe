//
//  SwiftDataStack.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import SwiftData

enum SwiftDataStack {
    static var container: ModelContainer = {
        do {
            let schema = Schema([
                RecordingSession.self,
                TranscriptionSegment.self
            ])
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()
}


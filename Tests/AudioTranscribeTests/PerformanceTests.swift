//
//  PerformanceTests.swift
//  AudioTranscribeTests
//
//  Created by Srilu Rao on 7/6/25.
//

import XCTest
@testable import AudioTranscribe
import SwiftData

final class PerformanceTests: XCTestCase {

    @MainActor func testSwiftDataPerformanceWithLargeDataset() throws {
        let context = SwiftDataStack.container.mainContext

        measure {
            for i in 0..<10000 {
                let session = RecordingSession(title: "Bulk \(i)")
                let segment = TranscriptionSegment(audioFilePath: "/tmp/audio\(i).m4a", session: session)
                session.segments.append(segment)
                context.insert(session)
                context.insert(segment)
            }

            try? context.save()
        }
    }

    func testTranscriptionServiceThroughput() async throws {
        let service = TranscriptionService()
        let urls = (1...3).compactMap { _ in Bundle.main.url(forResource: "short", withExtension: "m4a") }

        measure {
            Task {
                for url in urls {
                    _ = try await service.transcribeAudio(fileURL: url, languageCode: "en")
                }
            }
        }
    }
}

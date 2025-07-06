//
//  RecordingSessionTests.swift
//  AudioTranscribeTests
//
//  Created by Srilu Rao on 7/5/25.
//

import XCTest
import SwiftData
@testable import AudioTranscribe

final class RecordingSessionTests: XCTestCase {

    func testSessionInitialization() {
        let session = RecordingSession(title: "Test Session")
        XCTAssertEqual(session.title, "Test Session")
        XCTAssertTrue(session.segments.isEmpty)
    }

    func testAddSegmentToSession() {
        let session = RecordingSession(title: "With Segment")
        let segment = TranscriptionSegment(audioFilePath: "/tmp/audio.m4a", session: session)
        session.segments.append(segment)

        XCTAssertEqual(session.segments.count, 1)
        XCTAssertEqual(session.segments.first?.audioFilePath, "/tmp/audio.m4a")
    }
}

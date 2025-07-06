//
//  TranscriptionSegmentTests.swift
//  AudioTranscribeTests
//
//  Created by Srilu Rao on 7/6/25.
//

import XCTest
@testable import AudioTranscribe

final class TranscriptionSegmentTests: XCTestCase {
    func testSegmentInitialization() {
        let session = RecordingSession(title: "Mock")
        let segment = TranscriptionSegment(audioFilePath: "/tmp/test.m4a", session: session)

        XCTAssertEqual(segment.audioFilePath, "/tmp/test.m4a")
        XCTAssertEqual(segment.status, .pending)
        XCTAssertNil(segment.transcriptionText)
    }
}

//
//  TranscriptionServiceTests.swift
//  AudioTranscribeTests
//
//  Created by Srilu Rao on 7/6/25.
//

import XCTest
@testable import AudioTranscribe

final class TranscriptionServiceTests: XCTestCase {

    func testTranscriptionSuccess() async throws {
        let service = TranscriptionService()

        guard let url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "caf") else {
            XCTFail("Test audio file not found in bundle.")
            return
        }

        do {
            let text = try await service.transcribeAudio(fileURL: url, languageCode: "en")
            XCTAssertFalse(text.isEmpty)
        } catch {
            XCTFail("Transcription failed with: \(error)")
        }
    }

}

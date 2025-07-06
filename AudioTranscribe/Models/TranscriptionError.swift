//
//  TranscriptionError.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation

enum TranscriptionError: LocalizedError {
    case quotaExceeded
    case networkError(String)
    case decodeError

    var errorDescription: String? {
        switch self {
        case .quotaExceeded:
            return "You’ve exceeded your OpenAI Whisper API quota."
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodeError:
            return "Could not parse Whisper API response."
        }
    }
}


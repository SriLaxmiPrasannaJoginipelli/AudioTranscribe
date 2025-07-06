//
//  TranscriptionService.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation
import Speech

struct WhisperTranscriptionResponse: Codable {
    let text: String
}

class TranscriptionService {
    
    private var consecutiveFailures = 0
    private let maxFailuresBeforeFallback = 5

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["API_KEY"] as? String else {
            fatalError("Secrets.plist not found or invalid")
        }
        return key
    }

    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    
    func transcribeAudio(fileURL: URL, languageCode: String) async throws -> String {
        var delay: TimeInterval = 1
        var lastError: Error?
        
        let asset = AVAsset(url: fileURL)
        guard asset.isPlayable else {
            print("Corrupt or invalid audio asset")
            throw TranscriptionError.invalidFile
        }
        
        for attempt in 1...6 {  // 5 retries, fallback on 6th
            do {
                let transcription = try await performOpenAITranscription(fileURL: fileURL, languageCode: languageCode)
                consecutiveFailures = 0
                return transcription
            } catch {
                lastError = error
                consecutiveFailures += 1
                
                if consecutiveFailures >= maxFailuresBeforeFallback {
                    print("Fallback triggered after \(consecutiveFailures) failures")
                    return try await transcribeUsingApple(fileURL: fileURL)
                }
                
                print("Attempt \(attempt) failed. Retrying in \(delay)s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay *= 2 // Exponential backoff
            }
        }
        
        throw lastError ?? TranscriptionError.networkError("Unknown transcription failure")
    }

    private func performOpenAITranscription(fileURL: URL, languageCode: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = try createFormData(fileURL: fileURL, boundary: boundary, languageCode: languageCode)
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.networkError("No HTTP response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            if httpResponse.statusCode == 429 {
                throw TranscriptionError.quotaExceeded
            } else {
                throw TranscriptionError.networkError(errorMessage)
            }
        }

        do {
            let decoded = try JSONDecoder().decode(WhisperTranscriptionResponse.self, from: data)
            return decoded.text
        } catch {
            throw TranscriptionError.decodeError
        }
    }

    private func transcribeUsingApple(fileURL: URL) async throws -> String {
        print("Into apple transcriber")
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw TranscriptionError.fallbackUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }


    
    private func createFormData(fileURL: URL, boundary: String, languageCode: String) throws -> Data {
        var data = Data()
        let fileData = try Data(contentsOf: fileURL)

        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"

        // File
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)

        // Model
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)

        // Language
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(languageCode)\r\n".data(using: .utf8)!)

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }

}


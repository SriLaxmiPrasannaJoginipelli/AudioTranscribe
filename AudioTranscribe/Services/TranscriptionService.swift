//
//  TranscriptionService.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation

struct WhisperTranscriptionResponse: Codable {
    let text: String
}

enum TranscriptionError: Error {
    case quotaExceeded
    case networkError(String)
    case decodeError
}

class TranscriptionService {

    let apiKey = Bundle.main.infoDictionary?["ASSEMBLY_API_KEY"] as? String ?? ""
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!


    func transcribeAudio(fileURL: URL) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = try createFormData(fileURL: fileURL, boundary: boundary)
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

    private func createFormData(fileURL: URL, boundary: String) throws -> Data {
        var data = Data()
        let fileData = try Data(contentsOf: fileURL)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"segment.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}


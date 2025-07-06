//
//  URL+TempFile.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import Foundation

extension URL {
    static func tempRecordingURL(segmentIndex: Int) -> URL {
        let fileName = "segment-\(segmentIndex)-\(UUID().uuidString.prefix(6)).m4a"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
}


//
//  TranscriptionLanguage.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//
import Foundation

struct TranscriptionLanguage: Identifiable, Equatable, Hashable {
    var id: String { code }
    let code: String
    let name: String
}

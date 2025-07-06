//
//  SessionDetailView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import SwiftUI

struct SessionDetailView: View {
    @Bindable var session: RecordingSession

    var body: some View {
//        List {
//            ForEach(session.segments) { segment in
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Segment: \(segment.audioFileURL.lastPathComponent)")
//                        .font(.headline)
//                    Text(segment.transcriptionText ?? "⏳ Transcribing...")
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                    Text("Status: \(segment.status.rawValue)")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .padding(.vertical, 4)
//            }
//        }
        List {
            if session.segments.isEmpty {
                Text("No segments found.")
                    .foregroundColor(.gray)
            }
            
            ForEach(session.segments) { segment in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Segment: \(segment.audioFileURL.lastPathComponent)")
                        .font(.headline)
                    Text(segment.transcriptionText ?? "⏳ Waiting...")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Status: \(segment.status.rawValue)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }

        .navigationTitle(session.title)
    }
}



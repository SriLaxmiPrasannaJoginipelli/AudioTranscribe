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
        List {
            if session.segments.isEmpty {
                Text("No segments found.")
                    .foregroundColor(.gray)
            }
            
            ForEach(session.segments) { segment in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Segment: \(segment.audioFileURL.lastPathComponent)")
                        .font(.headline)
                    Text(segment.transcriptionText ?? "Waiting...")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Status: \(segment.status.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(statusColor(segment.status))
                }
            }
        }

        .navigationTitle(session.title)
    }
    func statusColor(_ status: TranscriptionStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .inProgress:return .blue
            
        }
    }

}



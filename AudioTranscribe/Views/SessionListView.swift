//
//  SessionListView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RecordingSession.createdAt, order: .reverse) var sessions: [RecordingSession]

    var body: some View {
        List {
            if sessions.isEmpty {
                emptyStateView
            } else {
                sessionsListView
            }
        }
        .listStyle(.plain)
        .navigationTitle("Recording Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
                .foregroundColor(.accentColor)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Start by creating your first recording session")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var sessionsListView: some View {
        ForEach(sessions) { session in
            sessionCardView(session: session)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .onDelete(perform: deleteSessions)
    }
    
    private func sessionCardView(session: RecordingSession) -> some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
               Spacer()              
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            context.delete(session)
        }
        try? context.save()
    }
}

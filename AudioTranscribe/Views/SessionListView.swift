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
    @Query(sort: \RecordingSession.createdAt, order: .reverse) var allSessions: [RecordingSession]
    @State private var searchText = ""

    // Group sessions by day
    private var groupedSessions: [String: [RecordingSession]] {
        let filtered = searchText.isEmpty ? allSessions : allSessions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }

        let grouped = Dictionary(grouping: filtered) { session in
            let date = Calendar.current.startOfDay(for: session.createdAt)
            return date.formatted(date: .abbreviated, time: .omitted)
        }

        return grouped
            .sorted(by: { $0.key > $1.key })
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    var body: some View {
        NavigationStack {
            List {
                if groupedSessions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { dateKey in
                        Section(header: Text(dateKey).font(.subheadline).foregroundColor(.secondary)) {
                            ForEach(groupedSessions[dateKey]!) { session in
                                sessionCardView(session: session)
                            }
                            .onDelete { indexSet in
                                deleteSessions(indexSet, in: dateKey)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search sessions")
            .navigationTitle("Sessions")
            .toolbar { EditButton() }
        }
    }

    private func deleteSessions(_ offsets: IndexSet, in dateKey: String) {
        guard var sessions = groupedSessions[dateKey] else { return }

        for index in offsets {
            let sessionToDelete = sessions[index]
            context.delete(sessionToDelete)
        }

        try? context.save()
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
                        .lineLimit(1)

                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Start by creating your first recording session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

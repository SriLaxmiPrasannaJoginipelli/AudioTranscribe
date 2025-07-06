//
//  SessionListView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \RecordingSession.createdAt, order: .reverse) var sessions: [RecordingSession]

    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading) {
                        Text(session.title).font(.headline)
                        Text(session.createdAt.formatted()).font(.caption)
                    }
                }
            }
        }
        .navigationTitle("All Sessions")
    }
}


#Preview {
    SessionListView()
}

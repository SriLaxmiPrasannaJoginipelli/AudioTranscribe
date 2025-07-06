//
//  RecordingView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: RecordingViewModel

    init() {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(context: SwiftDataStack.container.mainContext))
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(viewModel.isRecording ? "🎙️ Recording..." : "Ready")
                .font(.title2)
            Button(viewModel.isRecording ? "Stop Recording" : "Start Recording") {
                viewModel.toggleRecording()
            }
            .padding()
            .background(viewModel.isRecording ? .red : .green)
            .foregroundColor(.white)
            .clipShape(Capsule())
            NavigationLink("📁 View Sessions", destination: SessionListView())
        }
        .padding()
    }
}


#Preview {
    RecordingView()
}

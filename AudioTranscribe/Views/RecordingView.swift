//
//  RecordingView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//
import SwiftUI

struct RecordingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: RecordingViewModel

    init() {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(context: SwiftDataStack.container.mainContext))
    }

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    .frame(height: 180)
                    .shadow(radius: 8)

                VStack(spacing: 12) {
                    Text(viewModel.isRecording ? "🎙️ Recording..." : "Ready to Record")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Button(viewModel.isRecording ? "Stop" : "Start Recording") {
                        viewModel.toggleRecording()
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(viewModel.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                }
            }
            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Select Language")
                    .font(.headline)

                Picker("Language", selection: $viewModel.selectedLanguage) {
                    ForEach(RecordingViewModel.supportedLanguages) { lang in
                        Text(lang.name).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer()

            NavigationLink(destination: SessionListView()) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                    Text("View Sessions")
                        .fontWeight(.semibold)
                        .font(.title3)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color.blue, Color.teal], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .navigationTitle("Audio Transcriber")
    }
}

#Preview {
    RecordingView()
}

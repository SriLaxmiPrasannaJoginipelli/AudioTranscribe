//
//  RecordingView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/5/25.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var recorder = AudioRecorderService()
    
    var body: some View {
        VStack(spacing: 24) {
            Text(recorder.isRecording ? "🎙️ Recording..." : "Ready")
                .font(.title2)
            Button(recorder.isRecording ? "Stop" : "Start Recording") {
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    try? recorder.startRecording()
                }
            }
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
    }
}


#Preview {
    RecordingView()
}

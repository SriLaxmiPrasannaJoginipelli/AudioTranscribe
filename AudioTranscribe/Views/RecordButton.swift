//
//  RecordButton.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/6/25.
//

import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRecording ? "stop.fill" : "record.circle.fill")
                Text(isRecording ? "Stop Recording" : "Start Recording")
            }
            .font(.headline.weight(.semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                isRecording ?
                AnyView(Color.red.opacity(0.9)) :
                AnyView(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(
                color: isRecording ? .red.opacity(0.4) : .blue.opacity(0.3),
                radius: isRecording ? 10 : 8,
                x: 0,
                y: isRecording ? 6 : 4
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isRecording ? 1.03 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}



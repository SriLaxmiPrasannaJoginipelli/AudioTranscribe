//
//  AudioVisualizerView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/6/25.
//

import SwiftUI

struct AudioVisualizerView: View {
    let level: Float
    let duration: TimeInterval

    var body: some View {
        VStack(spacing: 12) {
            // Real-time waveform visualization
            WaveformBars(level: level)
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: CGFloat(duration.truncatingRemainder(dividingBy: 30) / 30))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: duration)

                Text(formatTime(duration))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
            }
            .frame(width: 70, height: 70)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}



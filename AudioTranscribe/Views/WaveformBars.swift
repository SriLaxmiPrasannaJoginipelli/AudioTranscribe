//
//  WaveformBars.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/6/25.
//

import SwiftUI

struct WaveformBars: View {
    let level: Float
    private let barCount = 15
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                let normalizedLevel = CGFloat(max(0, level + 60)) / 60
                let height = normalizedLevel * (20 + CGFloat(i % 3 * 5))
                let delay = Double(i) * 0.03
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(waveformColor(for: normalizedLevel))
                    .frame(width: 4, height: height)
                    .animation(
                        .spring(response: 0.2, dampingFraction: 0.5)
                        .delay(delay),
                        value: level
                    )
            }
        }
    }
    
    private func waveformColor(for level: CGFloat) -> Color {
        switch level {
        case 0.8...1.0: return .red
        case 0.5..<0.8: return .orange
        case 0.3..<0.5: return .yellow
        default: return .green
        }
    }
}



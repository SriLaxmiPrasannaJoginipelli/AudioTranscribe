//
//  ReadyToRecordView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/6/25.
//

import SwiftUI

struct ReadyToRecordView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 42))
                .symbolEffect(.pulse.wholeSymbol)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Ready to Record")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .transition(.opacity)
        }
    }
}

#Preview {
    ReadyToRecordView()
}

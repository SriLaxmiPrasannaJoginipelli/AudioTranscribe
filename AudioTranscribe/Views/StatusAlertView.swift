//
//  StatusAlertView.swift
//  AudioTranscribe
//
//  Created by Srilu Rao on 7/6/25.
//

import SwiftUI

struct StatusAlertView: View {
    let message: String?
    let error: String?
    
    var body: some View {
        VStack {
            if let message = message {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(message)
                }
                .padding()
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .foregroundColor(.white)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if let error = error {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .padding()
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .foregroundColor(.white)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 60)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message ?? error)
    }
}



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
        ZStack {
            
            AnimatedGradient(colors: [Color(.systemGroupedBackground),
                                      Color(.secondarySystemGroupedBackground),
                                      Color(.tertiarySystemGroupedBackground)])
            .ignoresSafeArea()
            .blur(radius: 20)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Audio Transcriber")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Record & Transcribe Audio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 28) {
                        // Recording Card
                        ZStack {
                            // Pulsing animation when recording
                            if viewModel.isRecording {
                                VStack{
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 300, height: 300)
                                        .scaleEffect(viewModel.isRecording ? 1.5 : 0.5)
                                        .opacity(viewModel.isRecording ? 0 : 0.5)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: viewModel.isRecording)
                                    
                                    Text("Elapsed: \(formatTime(viewModel.recordingDuration))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                }
                            }
                            
                            GlassCard {
                                VStack(spacing: 24) {
                                    HStack(spacing: 12) {
                                        Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(viewModel.isRecording ? .red : .blue)
                                            .symbolEffect(.bounce, value: viewModel.isRecording)
                                            .shadow(color: viewModel.isRecording ? .red.opacity(0.5) : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                        
                                        Text(viewModel.isRecording ? "Recording in progress" : "Ready to record")
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Button {
                                        viewModel.toggleRecording()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: viewModel.isRecording ? "stop.fill" : "record.circle.fill")
                                            Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                                        }
                                        .font(.headline.weight(.semibold))
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            viewModel.isRecording ?
                                            AnyView(Color.red.opacity(0.9)) :
                                                AnyView(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                                        )
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .shadow(color: viewModel.isRecording ? .red.opacity(0.5) : .blue.opacity(0.4),
                                                radius: viewModel.isRecording ? 10 : 8,
                                                x: 0, y: viewModel.isRecording ? 6 : 4)
                                        .scaleEffect(viewModel.isRecording ? 1.03 : 1)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isRecording)
                                    }
                                }
                                .padding(24)
                            }
                            .frame(height: 220)
                        }
                        .padding(.horizontal, 20)
                        
                        // Language Picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.indigo)
                                        .font(.title3)
                                    
                                    Text("TRANSCRIPTION LANGUAGE")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                }
                                
                                Picker("Language", selection: $viewModel.selectedLanguage) {
                                    ForEach(RecordingViewModel.supportedLanguages) { lang in
                                        Text(lang.name).tag(lang)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primary)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // View Sessions Button
                        NavigationLink(destination: SessionListView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .padding(.leading)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("View Sessions")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("See all your recordings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.gray.opacity(0.2), lineWidth: 1)
                                    .padding(.horizontal, 20))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        // Transcription feedback overlay
        .overlay(
            Group {
                if let message = viewModel.transcriptionMessage {
                    Text(message)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        .transition(.opacity)
                        .padding(.top, 80)
                } else if let error = viewModel.transcriptionError {
                    Text(error)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        .transition(.opacity)
                        .padding(.top, 80)
                }
            },
            alignment: .top
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.transcriptionMessage ?? viewModel.transcriptionError)

    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Glass background effect
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.2), lineWidth: 1)
            
            content
        }
    }
}

// Animated Gradient Background
struct AnimatedGradient: View {
    let colors: [Color]
    @State private var startPoint = UnitPoint(x: -1, y: 0)
    @State private var endPoint = UnitPoint(x: 2, y: 1)
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                startPoint = UnitPoint(x: 1, y: -1)
                endPoint = UnitPoint(x: 0, y: 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView()
    }
}

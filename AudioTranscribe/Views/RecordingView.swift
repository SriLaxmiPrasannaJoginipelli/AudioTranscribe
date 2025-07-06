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
            .overlay(
                Image(systemName: "circle.grid.cross")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.overlay)
                    .opacity(0.03)
                    .ignoresSafeArea()

            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                VStack(spacing: 4) {
                    Text("Audio Transcriber")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: viewModel.isRecording ? [.red, .orange] : [.indigo, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: viewModel.isRecording ? .red.opacity(0.2) : .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text("Record & Transcribe Audio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Enhanced recording card
                        ZStack {
                            // Audio-reactive background pulse
                            if viewModel.isRecording {
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                .red.opacity(0.1),
                                                .orange.opacity(0.3),
                                                .red.opacity(0.1)
                                            ]),
                                            center: .center,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(360)
                                        )
                                    )
                                    .frame(width: 300, height: 300)
                                    .scaleEffect(1.5 + (CGFloat(max(0, viewModel.currentLevel + 60)) / 60 * 0.3))
                                    .opacity(0.4)
                                    .animation(.easeOut(duration: 0.5), value: viewModel.currentLevel)
                            }
                            
                            GlassCard {
                                VStack(spacing: 24) {
                                    // Dynamic audio visualization
                                    if viewModel.isRecording {
                                        AudioVisualizerView(level: viewModel.currentLevel,
                                                          duration: viewModel.recordingDuration)
                                    } else {
                                        ReadyToRecordView()
                                    }
                                    
                                    // Enhanced record button
                                    RecordButton(isRecording: viewModel.isRecording) {
                                        viewModel.toggleRecording()
                                    }
                                    .frame(height: 50)
                                }
                                .padding(24)
                            }
                            .frame(height: 220)
                        }
                        .padding(.horizontal, 20)
                        
                        // Language Picker with improved design
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("TRANSCRIPTION LANGUAGE", systemImage: "globe")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Picker("Language", selection: $viewModel.selectedLanguage) {
                                    ForEach(RecordingViewModel.supportedLanguages) { lang in
                                        Text(lang.name).tag(lang)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Enhanced sessions button
                        NavigationLink(destination: SessionListView()) {
                            GlassCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "folder.fill")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .indigo],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    
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
                                }
                                .padding()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        // Enhanced status alerts
        .overlay(
            StatusAlertView(message: viewModel.transcriptionMessage,
                          error: viewModel.transcriptionError)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isRecording)
    }
    
}

// MARK: - Subviews
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            
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

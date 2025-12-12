import SwiftUI
import Observation

struct QuickOptimizeView: View {
    @Environment(AppState.self) var appState

    @State private var inputText: String = ""
    @State private var optimizedText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedMode: OptimizeMode = .detailed

    var body: some View {
        VStack(spacing: Spacing.md) {
            // MARK: - Input
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.bodyRegular)
                    .scrollContentBackground(.hidden)
                    .background(Color.surface)
                    .foregroundStyle(Color.textPrimary)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.border, lineWidth: 1))

                if inputText.isEmpty {
                    Text("Enter prompt to optimize...")
                        .foregroundStyle(Color.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }

            // MARK: - Controls
            HStack {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(OptimizeMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                Spacer()

                Button(action: optimize) {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Optimize", systemImage: "bolt.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color.primaryApp)
                .disabled(inputText.isEmpty || isLoading)
            }

            // MARK: - Output
            if !optimizedText.isEmpty {
                TextEditor(text: .constant(optimizedText))
                    .font(.bodyRegular)
                    .scrollContentBackground(.hidden)
                    .background(Color.infoBackground.opacity(0.1))
                    .foregroundStyle(Color.textPrimary)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.sm).stroke(Color.primaryApp.opacity(0.3), lineWidth: 1))
            }

            // MARK: - Actions & Error
            HStack {
                if let error = errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.error)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Color.error)
                    Spacer()
                } else if !optimizedText.isEmpty {
                    Button(action: { appState.clipboardService.copy(optimizedText) }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Color.surface)
                }
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Actions
    @MainActor
    private func optimize() {
        guard !inputText.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        optimizedText = ""

        Task {
            do {
                for try await chunk in appState.aiService.optimizeStream(prompt: inputText, mode: selectedMode) {
                    optimizedText += chunk
                }
                // Save to history after successful optimization
                let prompt = Prompt(
                    title: String(inputText.prefix(50)),
                    originalContent: inputText,
                    optimizedContent: optimizedText,
                    optimizeMode: selectedMode
                )
                try appState.storageService.savePrompt(prompt)
            } catch {
                errorMessage = error.localizedDescription
                print("Quick Optimize Error: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

#Preview {
    QuickOptimizeView()
        .frame(width: 360, height: 500)
}

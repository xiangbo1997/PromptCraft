import SwiftUI
import SwiftData
import Observation

struct RecentPromptsView: View {
    @Environment(AppState.self) var appState
    
    @State private var recentPrompts: [Prompt] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading recent prompts...")
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .padding()
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if recentPrompts.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textTertiary)
                    Text("No recent prompts.")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(recentPrompts.prefix(5)) { prompt in // Show up to 5 recent prompts
                        HStack {
                            VStack(alignment: .leading) {
                                Text(prompt.title)
                                    .font(.bodyRegular)
                                    .lineLimit(1)
                                Text(prompt.optimizedContent)
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button(action: { appState.clipboardService.copy(prompt.optimizedContent) }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Copy to clipboard")
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear(perform: loadRecentPrompts)
    }
    
    @MainActor
    private func loadRecentPrompts() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                // Fetch prompts sorted by last used, newest first, limit to a few for menu bar
                let descriptor = FetchDescriptor<Prompt>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
                self.recentPrompts = try appState.storageService.fetchPrompts()
                self.recentPrompts.sort { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            } catch {
                errorMessage = error.localizedDescription
                print("Error loading recent prompts for menu bar: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

#Preview {
    RecentPromptsView()
        .environment(AppState())
        .environment(\.modelContext, PromptCraftApp.sharedModelContainer.mainContext) // Provide a model context for preview
        .frame(width: 360, height: 500)
}

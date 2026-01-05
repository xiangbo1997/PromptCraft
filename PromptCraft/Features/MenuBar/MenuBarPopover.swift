import SwiftUI
import Observation

struct MenuBarPopover: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab: MenuBarTab = .quickOptimize
    
    enum MenuBarTab: String, CaseIterable, Identifiable {
        case quickOptimize = "Optimize"
        case recentPrompts = "Recent"
        case favorites = "Favorites"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Tab Selector
            Picker("", selection: $selectedTab) {
                ForEach(MenuBarTab.allCases) { tab in
                    Text(tab.rawValue)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            
            Divider()
            
            // MARK: - Tab Content
            switch selectedTab {
            case .quickOptimize:
                QuickOptimizeView()
            case .recentPrompts:
                RecentPromptsView()
            case .favorites:
                Text("Favorites (Coming Soon)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            
            // MARK: - Footer Actions
            VStack(spacing: Spacing.sm) {
                Button(action: { appState.openMainWindow() }) {
                    HStack {
                        Image(systemName: "app.fill")
                        Text("Open Main Window")
                        Spacer()
                        Text("⌘⇧P")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: { appState.navigateToTab(.settings) }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Preferences...")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: { NSApp.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit SparkPrompt")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MenuBarPopover()
        .frame(width: 360, height: 500)
}

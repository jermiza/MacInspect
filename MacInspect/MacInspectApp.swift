import SwiftUI

@main
struct MacInspectApp: App {
    @StateObject private var manager = InspectionManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(manager)
                .navigationTitle("MacInspect")
        }
        .windowStyle(TitleBarWindowStyle())
        .commands {
            // Add custom File commands
            CommandGroup(replacing: .newItem) {
                Button("Export Report...") {
                    NotificationCenter.default.post(name: .exportReportRequested, object: nil)
                }
                .keyboardShortcut("E", modifiers: .command)
                .disabled(!manager.isInspectionFinished)
            }
        }
    }
}

// Notification extension to link Menu Item trigger to View events
extension Notification.Name {
    static let exportReportRequested = Notification.Name("exportReportRequested")
}

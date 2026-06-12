import SwiftUI

struct MainView: View {
    @EnvironmentObject var manager: InspectionManager
    
    var body: some View {
        NavigationSplitView {
            List(selection: $manager.currentModuleId) {
                // Intro link
                NavigationLink(value: "welcome") {
                    HStack {
                        Image(systemName: "hand.wave")
                            .foregroundColor(.blue)
                        Text("Welcome")
                            .fontWeight(.medium)
                    }
                }
                
                Section("Hardware Tests") {
                    ForEach(manager.activeModules) { module in
                        NavigationLink(value: module.id) {
                            HStack {
                                Image(systemName: module.iconName)
                                    .foregroundColor(module.status == .pending ? .secondary : .blue)
                                Text(module.name)
                                Spacer()
                                StatusDot(status: module.status)
                            }
                        }
                    }
                }
                
                Section("Specifications") {
                    NavigationLink(value: "system") {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("System Information")
                        }
                    }
                }
                
                Section("Summary") {
                    NavigationLink(value: "report") {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(manager.isInspectionFinished ? .green : .secondary)
                            Text("Final Report")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section("Future Expansion Specs") {
                    ForEach(manager.placeholderModules) { module in
                        NavigationLink(value: module.id) {
                            HStack {
                                Image(systemName: module.iconName)
                                    .foregroundColor(.secondary)
                                Text(module.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, idealWidth: 220)
        } detail: {
            DetailResolver(moduleId: manager.currentModuleId ?? "welcome")
        }
        .frame(minWidth: 900, minHeight: 650)
        .onAppear {
            if manager.currentModuleId == nil {
                manager.currentModuleId = "welcome"
            }
        }
    }
}

// Router resolver translating selected ID to target views
struct DetailResolver: View {
    var moduleId: String
    
    var body: some View {
        switch moduleId {
        case "welcome":
            WelcomeView()
        case "keyboard":
            KeyboardTestView()
        case "display":
            DisplayTestView()
        case "trackpad":
            TrackpadTestView()
        case "speaker":
            SpeakerTestView()
        case "microphone":
            MicrophoneTestView()
        case "camera":
            CameraTestView()
        case "battery":
            BatteryTestView()
        case "system":
            SystemInfoView()
        case "report":
            FinalReportView()
        case "touchbar", "usb", "ssd", "deadpixel", "extdisplay":
            FutureTestsView(moduleId: moduleId)
        default:
            WelcomeView()
        }
    }
}

// Sidebar Status Dot helper
struct StatusDot: View {
    var status: TestStatus
    
    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .shadow(color: dotColor.opacity(0.3), radius: 1, x: 0, y: 1)
    }
    
    private var dotColor: Color {
        switch status {
        case .passed: return .green
        case .failed: return .red
        case .skipped: return .orange
        case .running: return .blue
        case .pending: return .secondary.opacity(0.4)
        }
    }
}

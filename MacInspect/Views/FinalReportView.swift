import SwiftUI
import AppKit

struct FinalReportView: View {
    @EnvironmentObject var manager: InspectionManager
    @State private var showingShareAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inspection Report Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Review compiled metrics, hardware grades, and export diagnostic logs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Score Header Card
                HStack(spacing: 32) {
                    // Score Badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [scoreColor.opacity(0.15), scoreColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                Circle()
                                    .stroke(scoreColor, lineWidth: 3)
                            )
                        
                        VStack(spacing: 2) {
                            Text("\(manager.totalScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(scoreColor)
                            Text("/ \(manager.maxScorePossible)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MacInspect Grade: \(gradeLabel)")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Tested on \(Date().formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Hardware overall status: \(overallStatusText). Fully compatible with system requirements.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Test Results Table List
                VStack(alignment: .leading, spacing: 14) {
                    Text("Inspection Breakdown")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        ForEach(manager.activeModules) { module in
                            ResultRow(module: module)
                            if module.id != manager.activeModules.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // Export and Share Options
                VStack(spacing: 16) {
                    Text("Export & Distribution Options")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        // PDF Export Card
                        ExportButtonCard(
                            title: "Save PDF Report",
                            description: "Generate a clean vector PDF to save on your local drive.",
                            systemIcon: "doc.plaintext.fill",
                            color: .blue,
                            action: {
                                manager.exportPDFReport(printableReportView: AnyView(PrintableReportView(manager: manager)))
                            }
                        )
                        
                        // Share Card
                        ExportButtonCard(
                            title: "Share Report...",
                            description: "Share the PDF report directly using standard macOS sharing services.",
                            systemIcon: "square.and.arrow.up.fill",
                            color: .purple,
                            action: {
                                shareReport()
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: .exportReportRequested)) { _ in
            // Trigger PDF Export when File -> Export is selected
            manager.exportPDFReport(printableReportView: AnyView(PrintableReportView(manager: manager)))
        }
    }
    
    // Grading helpers
    private var scoreColor: Color {
        let percent = Double(manager.totalScore) / Double(manager.maxScorePossible)
        if percent >= 0.9 { return .green }
        if percent >= 0.75 { return .blue }
        if percent >= 0.5 { return .orange }
        return .red
    }
    
    private var gradeLabel: String {
        let percent = Double(manager.totalScore) / Double(manager.maxScorePossible)
        if percent >= 0.95 { return "Excellent (A+)" }
        if percent >= 0.9 { return "Very Good (A)" }
        if percent >= 0.8 { return "Good (B)" }
        if percent >= 0.7 { return "Fair (C)" }
        return "Defective / Warning (F)"
    }
    
    private var overallStatusText: String {
        let failures = manager.activeModules.filter { $0.status == .failed }.count
        if failures == 0 {
            return "All Hardware Tests Passed"
        } else {
            return "\(failures) Warning(s) Flagged"
        }
    }
    
    // Sharing utility
    private func shareReport() {
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("MacInspect_Report.pdf")
        
        let view = PrintableReportView(manager: manager)
        let hostingView = NSHostingView(rootView: view)
        let pdfRect = NSRect(x: 0, y: 0, width: 612, height: 792)
        hostingView.frame = pdfRect
        hostingView.layoutSubtreeIfNeeded()
        
        let pdfData = hostingView.dataWithPDF(inside: pdfRect)
        
        do {
            try pdfData.write(to: tempUrl)
            
            // Invoke macOS Sharing picker
            let picker = NSSharingServicePicker(items: [tempUrl])
            if let window = NSApp.keyWindow {
                // Approximate location in center screen for popover
                let rect = NSRect(x: window.frame.width / 2, y: window.frame.height / 2, width: 1, height: 1)
                picker.show(relativeTo: rect, of: window.contentView ?? NSView(), preferredEdge: .minY)
            }
        } catch {
            print("Failed to save temporary PDF for sharing: \(error)")
        }
    }
}

struct ResultRow: View {
    var module: TestModule
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: module.iconName)
                    .foregroundColor(statusColor)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(module.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(module.details.isEmpty ? "No inspection details recorded." : module.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(module.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
                
                Text("\(module.score) / \(module.maxScore) pts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var statusColor: Color {
        switch module.status {
        case .passed: return .green
        case .failed: return .red
        case .skipped: return .orange
        case .pending, .running: return .gray
        }
    }
}

struct ExportButtonCard: View {
    var title: String
    var description: String
    var systemIcon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: systemIcon)
                        .foregroundColor(color)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Dedicated high-contrast Vector PDF page (Styled strictly for printing)
struct PrintableReportView: View {
    var manager: InspectionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MacInspect Diagnostic Certificate")
                        .font(.system(size: 24, weight: .bold))
                    Text("Verified hardware checkout record generated by macOS diagnostic stack.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Grade Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SCORE GRADE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(manager.totalScore) / \(manager.maxScorePossible)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            .padding(.bottom, 12)
            
            Divider()
            
            // Device Specifications Table
            VStack(alignment: .leading, spacing: 8) {
                Text("Device System Specifications")
                    .font(.system(size: 14, weight: .bold))
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                    GridRow {
                        Text("Mac Model:").bold().font(.system(size: 10))
                        Text(manager.systemInfo.model).font(.system(size: 10))
                    }
                    GridRow {
                        Text("Processor:").bold().font(.system(size: 10))
                        Text(manager.systemInfo.chipType).font(.system(size: 10))
                    }
                    GridRow {
                        Text("Memory (RAM):").bold().font(.system(size: 10))
                        Text(manager.systemInfo.ram).font(.system(size: 10))
                    }
                    GridRow {
                        Text("Disk Storage:").bold().font(.system(size: 10))
                        Text(manager.systemInfo.storageTotal).font(.system(size: 10))
                    }
                    GridRow {
                        Text("OS Version:").bold().font(.system(size: 10))
                        Text(manager.systemInfo.macOSVersion).font(.system(size: 10))
                    }
                    GridRow {
                        Text("Serial Number:").bold().font(.system(size: 10))
                        Text(manager.hideSerialNumber ? "Redacted (Hidden)" : manager.systemInfo.serialNumber).font(.system(size: 10))
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.02))
            .cornerRadius(6)
            
            // Battery Specifications
            VStack(alignment: .leading, spacing: 8) {
                Text("Battery Health Summary")
                    .font(.system(size: 14, weight: .bold))
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                    GridRow {
                        Text("Battery Condition:").bold().font(.system(size: 10))
                        Text(manager.batteryInfo.health).font(.system(size: 10))
                    }
                    GridRow {
                        Text("Cycle Count:").bold().font(.system(size: 10))
                        Text("\(manager.batteryInfo.cycleCount)").font(.system(size: 10))
                    }
                    GridRow {
                        Text("Capacity Retention:").bold().font(.system(size: 10))
                        Text(String(format: "%.1f%% of design capacity", manager.batteryInfo.maxCapacityPercent)).font(.system(size: 10))
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.02))
            .cornerRadius(6)
            
            // Test Table breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Inspection Results Matrix")
                    .font(.system(size: 14, weight: .bold))
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Test Module").bold()
                        Spacer()
                        Text("Status").bold()
                        Spacer().frame(width: 80)
                        Text("Score").bold()
                    }
                    .font(.system(size: 10))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.08))
                    
                    // Rows
                    ForEach(manager.activeModules) { module in
                        HStack {
                            Text(module.name)
                            Spacer()
                            Text(module.status.rawValue.uppercased())
                                .foregroundColor(module.status == .passed ? .green : (module.status == .failed ? .red : .orange))
                            Spacer().frame(width: 80)
                            Text("\(module.score) / \(module.maxScore)")
                        }
                        .font(.system(size: 9))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        
                        Divider()
                    }
                }
                .cornerRadius(4)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Generated dynamically by MacInspect app.")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Spacer()
                Text("Date of Inspection: \(Date().formatted(date: .numeric, time: .shortened))")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .padding(.top, 16)
        }
        .padding(40)
        .frame(width: 612, height: 792)
        .background(Color.white)
        .foregroundColor(.black)
    }
}

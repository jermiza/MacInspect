import SwiftUI
import PDFKit
import OSLog

class InspectionManager: ObservableObject {
    private let logger = Logger(subsystem: "com.macinspect.app", category: "Inspection")
    
    // Test Modules
    @Published var activeModules: [TestModule] = [
        TestModule(id: "keyboard", name: "Keyboard Test", iconName: "keyboard", maxScore: 15),
        TestModule(id: "display", name: "Display Test", iconName: "display", maxScore: 15),
        TestModule(id: "trackpad", name: "Trackpad Test", iconName: "hand.draw", maxScore: 15),
        TestModule(id: "speaker", name: "Speaker Test", iconName: "speaker.wave.2", maxScore: 15),
        TestModule(id: "microphone", name: "Microphone Test", iconName: "mic", maxScore: 15),
        TestModule(id: "camera", name: "Camera Test", iconName: "camera", maxScore: 15),
        TestModule(id: "battery", name: "Battery Health", iconName: "battery.100", maxScore: 10)
    ]
    
    @Published var placeholderModules: [TestModule] = [
        TestModule(id: "touchbar", name: "Touch Bar", iconName: "hand.tap", status: .pending, maxScore: 0, isPlaceholder: true),
        TestModule(id: "usb", name: "USB Ports", iconName: "cable.connector", status: .pending, maxScore: 0, isPlaceholder: true),
        TestModule(id: "ssd", name: "SSD Health", iconName: "internaldrive", status: .pending, maxScore: 0, isPlaceholder: true),
        TestModule(id: "deadpixel", name: "Auto Dead Pixel", iconName: "eye.glow", status: .pending, maxScore: 0, isPlaceholder: true),
        TestModule(id: "extdisplay", name: "External Display", iconName: "desktopcomputer", status: .pending, maxScore: 0, isPlaceholder: true)
    ]
    
    @Published var currentModuleId: String? = nil // nil means Welcome screen
    @Published var batteryInfo = BatteryInfo()
    @Published var systemInfo = SystemInfo()
    @Published var isInspectionFinished = false
    @Published var hideSerialNumber = false
    
    // Overall calculations
    var totalScore: Int {
        activeModules.reduce(0) { $0 + $1.score }
    }
    
    var maxScorePossible: Int {
        activeModules.reduce(0) { $0 + $1.maxScore }
    }
    
    var progressFraction: Double {
        let completed = activeModules.filter { $0.status != .pending && $0.status != .running }.count
        return Double(completed) / Double(activeModules.count)
    }
    
    init() {
        logger.log("MacInspect InspectionManager initialized.")
    }
    
    func startInspection() {
        logger.log("Starting hardware inspection.")
        isInspectionFinished = false
        // Reset modules
        for i in 0..<activeModules.count {
            activeModules[i].status = .pending
            activeModules[i].score = 0
            activeModules[i].details = ""
        }
        currentModuleId = activeModules.first?.id
    }
    
    func updateModuleStatus(id: String, status: TestStatus, score: Int, details: String) {
        logger.log("Updating test module '\(id)' to status: \(status.rawValue) with score: \(score).")
        if let idx = activeModules.firstIndex(where: { $0.id == id }) {
            activeModules[idx].status = status
            activeModules[idx].score = score
            activeModules[idx].details = details
        }
        
        checkIfFinished()
    }
    
    func skipModule(id: String) {
        logger.log("Skipping test module '\(id)'.")
        updateModuleStatus(id: id, status: .skipped, score: 0, details: "Skipped by user")
        advanceToNext(after: id)
    }
    
    func advanceToNext(after id: String) {
        if let idx = activeModules.firstIndex(where: { $0.id == id }) {
            if idx + 1 < activeModules.count {
                currentModuleId = activeModules[idx + 1].id
            } else {
                currentModuleId = "report" // go to report
                isInspectionFinished = true
            }
        }
    }
    
    private func checkIfFinished() {
        let allDone = activeModules.allSatisfy { $0.status != .pending && $0.status != .running }
        if allDone {
            isInspectionFinished = true
        }
    }
    
    func exportPDFReport(printableReportView: AnyView) {
        logger.log("Exporting PDF report.")
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "MacInspect_Report_\(systemInfo.model.replacingOccurrences(of: " ", with: "_")).pdf"
        savePanel.title = "Save MacInspect Report"
        
        savePanel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = savePanel.url else { return }
            
            // Render SwiftUI view to PDF
            let pdfData = self.renderViewToPDFData(view: printableReportView)
            
            do {
                try pdfData?.write(to: url)
                self.logger.log("Successfully saved report PDF to \(url.path).")
            } catch {
                self.logger.log("Error saving PDF: \(error.localizedDescription).")
            }
        }
    }
    
    private func renderViewToPDFData(view: AnyView) -> Data? {
        let hostingView = NSHostingView(rootView: view)
        // Standard US Letter width: 612 pt, height: 792 pt
        let pdfRect = NSRect(x: 0, y: 0, width: 612, height: 792)
        hostingView.frame = pdfRect
        
        // Ensure SwiftUI does layout
        hostingView.layoutSubtreeIfNeeded()
        
        // Native macOS vector PDF generation
        return hostingView.dataWithPDF(inside: pdfRect)
    }
}

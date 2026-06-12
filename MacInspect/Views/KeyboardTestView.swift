import SwiftUI

struct KeyDefinition: Identifiable {
    var id: String
    var label: String
    var width: CGFloat
    var height: CGFloat = 36
}

struct KeyboardTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @StateObject private var monitor = KeyboardMonitor()
    
    // Keyboard Layout Row Specifications
    private let row1: [KeyDefinition] = [
        KeyDefinition(id: "Esc", label: "esc", width: 48),
        KeyDefinition(id: "F1", label: "F1", width: 32),
        KeyDefinition(id: "F2", label: "F2", width: 32),
        KeyDefinition(id: "F3", label: "F3", width: 32),
        KeyDefinition(id: "F4", label: "F4", width: 32),
        KeyDefinition(id: "F5", label: "F5", width: 32),
        KeyDefinition(id: "F6", label: "F6", width: 32),
        KeyDefinition(id: "F7", label: "F7", width: 32),
        KeyDefinition(id: "F8", label: "F8", width: 32),
        KeyDefinition(id: "F9", label: "F9", width: 32),
        KeyDefinition(id: "F10", label: "F10", width: 32),
        KeyDefinition(id: "F11", label: "F11", width: 32),
        KeyDefinition(id: "F12", label: "F12", width: 32),
        KeyDefinition(id: "Power", label: "⌽", width: 48)
    ]
    
    private let row2: [KeyDefinition] = [
        KeyDefinition(id: "`", label: "~ \n `", width: 38),
        KeyDefinition(id: "1", label: "! \n 1", width: 38),
        KeyDefinition(id: "2", label: "@ \n 2", width: 38),
        KeyDefinition(id: "3", label: "# \n 3", width: 38),
        KeyDefinition(id: "4", label: "$ \n 4", width: 38),
        KeyDefinition(id: "5", label: "% \n 5", width: 38),
        KeyDefinition(id: "6", label: "^ \n 6", width: 38),
        KeyDefinition(id: "7", label: "& \n 7", width: 38),
        KeyDefinition(id: "8", label: "* \n 8", width: 38),
        KeyDefinition(id: "9", label: "( \n 9", width: 38),
        KeyDefinition(id: "0", label: ") \n 0", width: 38),
        KeyDefinition(id: "-", label: "_ \n -", width: 38),
        KeyDefinition(id: "=", label: "+ \n =", width: 38),
        KeyDefinition(id: "Delete", label: "delete", width: 62)
    ]
    
    private let row3: [KeyDefinition] = [
        KeyDefinition(id: "Tab", label: "tab", width: 55),
        KeyDefinition(id: "Q", label: "Q", width: 38),
        KeyDefinition(id: "W", label: "W", width: 38),
        KeyDefinition(id: "E", label: "E", width: 38),
        KeyDefinition(id: "R", label: "R", width: 38),
        KeyDefinition(id: "T", label: "T", width: 38),
        KeyDefinition(id: "Y", label: "Y", width: 38),
        KeyDefinition(id: "U", label: "U", width: 38),
        KeyDefinition(id: "I", label: "I", width: 38),
        KeyDefinition(id: "O", label: "O", width: 38),
        KeyDefinition(id: "P", label: "P", width: 38),
        KeyDefinition(id: "[", label: "{ \n [", width: 38),
        KeyDefinition(id: "]", label: "} \n ]", width: 38),
        KeyDefinition(id: "\\", label: "| \n \\", width: 45)
    ]
    
    private let row4: [KeyDefinition] = [
        KeyDefinition(id: "CapsLock", label: "caps lock", width: 66),
        KeyDefinition(id: "A", label: "A", width: 38),
        KeyDefinition(id: "S", label: "S", width: 38),
        KeyDefinition(id: "D", label: "D", width: 38),
        KeyDefinition(id: "F", label: "F", width: 38),
        KeyDefinition(id: "G", label: "G", width: 38),
        KeyDefinition(id: "H", label: "H", width: 38),
        KeyDefinition(id: "J", label: "J", width: 38),
        KeyDefinition(id: "K", label: "K", width: 38),
        KeyDefinition(id: "L", label: "L", width: 38),
        KeyDefinition(id: ";", label: ": \n ;", width: 38),
        KeyDefinition(id: "'", label: "\" \n '", width: 38),
        KeyDefinition(id: "Return", label: "return", width: 64)
    ]
    
    private let row5: [KeyDefinition] = [
        KeyDefinition(id: "ShiftL", label: "shift", width: 80),
        KeyDefinition(id: "Z", label: "Z", width: 38),
        KeyDefinition(id: "X", label: "X", width: 38),
        KeyDefinition(id: "C", label: "C", width: 38),
        KeyDefinition(id: "V", label: "V", width: 38),
        KeyDefinition(id: "B", label: "B", width: 38),
        KeyDefinition(id: "N", label: "N", width: 38),
        KeyDefinition(id: "M", label: "M", width: 38),
        KeyDefinition(id: ",", label: "< \n ,", width: 38),
        KeyDefinition(id: ".", label: "> \n .", width: 38),
        KeyDefinition(id: "/", label: "? \n /", width: 38),
        KeyDefinition(id: "ShiftR", label: "shift", width: 88)
    ]
    
    // Total standard keys count we expect the user to test (excluding Power, Fn, and function keys that may overlap with system behavior)
    private var totalKeysToTest: Set<String> {
        var keys = Set<String>()
        [row2, row3, row4, row5].forEach { row in
            row.forEach { keys.insert($0.id) }
        }
        // Add bottom row keys (excluding Fn which some OS blocks)
        keys.insert("CmdL")
        keys.insert("CmdR")
        keys.insert("OptL")
        keys.insert("OptR")
        keys.insert("CtrlL")
        keys.insert("Space")
        keys.insert("ArrowL")
        keys.insert("ArrowR")
        keys.insert("ArrowU")
        keys.insert("ArrowD")
        return keys
    }
    
    var testedKeysCount: Int {
        monitor.testedKeys.intersection(totalKeysToTest).count
    }
    
    var progressPercent: Int {
        guard !totalKeysToTest.isEmpty else { return 0 }
        return Int(Double(testedKeysCount) / Double(totalKeysToTest.count) * 100.0)
    }
    
    var missingKeys: [String] {
        totalKeysToTest.subtracting(monitor.testedKeys).sorted()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard Layout Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Press all highlighted keys on your keyboard to verify functionality.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progressPercent)% Complete")
                        .font(.headline)
                        .foregroundColor(progressPercent == 100 ? .green : .blue)
                    Text("\(testedKeysCount) / \(totalKeysToTest.count) Keys Tested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                    Capsule()
                        .fill(progressPercent == 100 ? Color.green : Color.blue)
                        .frame(width: geo.size.width * CGFloat(progressPercent) / 100.0)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 20) {
                // Keyboard frame
                VStack(spacing: 6) {
                    // Row 1 (Functions)
                    HStack(spacing: 5) {
                        ForEach(row1) { key in
                            KeyView(key: key, isPressed: monitor.pressedKeys.contains(key.id), isTested: monitor.testedKeys.contains(key.id))
                        }
                    }
                    
                    // Row 2 (Numbers)
                    HStack(spacing: 5) {
                        ForEach(row2) { key in
                            KeyView(key: key, isPressed: monitor.pressedKeys.contains(key.id), isTested: monitor.testedKeys.contains(key.id))
                        }
                    }
                    
                    // Row 3 (QWERTY)
                    HStack(spacing: 5) {
                        ForEach(row3) { key in
                            KeyView(key: key, isPressed: monitor.pressedKeys.contains(key.id), isTested: monitor.testedKeys.contains(key.id))
                        }
                    }
                    
                    // Row 4 (ASDF)
                    HStack(spacing: 5) {
                        ForEach(row4) { key in
                            KeyView(key: key, isPressed: monitor.pressedKeys.contains(key.id), isTested: monitor.testedKeys.contains(key.id))
                        }
                    }
                    
                    // Row 5 (ZXCV)
                    HStack(spacing: 5) {
                        ForEach(row5) { key in
                            KeyView(key: key, isPressed: monitor.pressedKeys.contains(key.id), isTested: monitor.testedKeys.contains(key.id))
                        }
                    }
                    
                    // Row 6 (Bottom row with arrow keys)
                    HStack(spacing: 5) {
                        KeyView(key: KeyDefinition(id: "Fn", label: "fn", width: 40), isPressed: monitor.pressedKeys.contains("Fn"), isTested: monitor.testedKeys.contains("Fn"))
                        KeyView(key: KeyDefinition(id: "CtrlL", label: "control", width: 40), isPressed: monitor.pressedKeys.contains("CtrlL"), isTested: monitor.testedKeys.contains("CtrlL"))
                        KeyView(key: KeyDefinition(id: "OptL", label: "option", width: 40), isPressed: monitor.pressedKeys.contains("OptL"), isTested: monitor.testedKeys.contains("OptL"))
                        KeyView(key: KeyDefinition(id: "CmdL", label: "command", width: 50), isPressed: monitor.pressedKeys.contains("CmdL"), isTested: monitor.testedKeys.contains("CmdL"))
                        
                        KeyView(key: KeyDefinition(id: "Space", label: "space", width: 200), isPressed: monitor.pressedKeys.contains("Space"), isTested: monitor.testedKeys.contains("Space"))
                        
                        KeyView(key: KeyDefinition(id: "CmdR", label: "command", width: 50), isPressed: monitor.pressedKeys.contains("CmdR"), isTested: monitor.testedKeys.contains("CmdR"))
                        KeyView(key: KeyDefinition(id: "OptR", label: "option", width: 40), isPressed: monitor.pressedKeys.contains("OptR"), isTested: monitor.testedKeys.contains("OptR"))
                        
                        // Arrows block
                        KeyView(key: KeyDefinition(id: "ArrowL", label: "◀", width: 34), isPressed: monitor.pressedKeys.contains("ArrowL"), isTested: monitor.testedKeys.contains("ArrowL"))
                        
                        VStack(spacing: 2) {
                            KeyView(key: KeyDefinition(id: "ArrowU", label: "▲", width: 34, height: 17), isPressed: monitor.pressedKeys.contains("ArrowU"), isTested: monitor.testedKeys.contains("ArrowU"))
                            KeyView(key: KeyDefinition(id: "ArrowD", label: "▼", width: 34, height: 17), isPressed: monitor.pressedKeys.contains("ArrowD"), isTested: monitor.testedKeys.contains("ArrowD"))
                        }
                        
                        KeyView(key: KeyDefinition(id: "ArrowR", label: "▶", width: 34), isPressed: monitor.pressedKeys.contains("ArrowR"), isTested: monitor.testedKeys.contains("ArrowR"))
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                )
                
                // Sidebar listing missing keys
                VStack(alignment: .leading, spacing: 12) {
                    Text("Missing Keys (\(missingKeys.count))")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                            ForEach(missingKeys, id: \.self) { key in
                                Text(key)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .frame(width: 180)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button("Skip Test") {
                    manager.skipModule(id: "keyboard")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    let score = Int(Double(testedKeysCount) / Double(totalKeysToTest.count) * 15.0)
                    let status: TestStatus = (testedKeysCount == totalKeysToTest.count) ? .passed : .failed
                    let details = "Tested \(testedKeysCount) of \(totalKeysToTest.count) standard keys."
                    
                    manager.updateModuleStatus(id: "keyboard", status: status, score: score, details: details)
                    manager.advanceToNext(after: "keyboard")
                }) {
                    Text(progressPercent == 100 ? "Finish & Continue" : "Submit Partial & Continue")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(progressPercent == 100 ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

struct KeyView: View {
    var key: KeyDefinition
    var isPressed: Bool
    var isTested: Bool
    
    var body: some View {
        Text(key.label)
            .font(.system(size: key.label.contains("\n") ? 8 : 11, weight: .regular))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .foregroundColor(isPressed ? .white : (isTested ? .white : .primary))
            .frame(width: key.width, height: key.height)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        isPressed
                        ? Color.blue
                        : (isTested ? Color.green : Color(NSColor.controlBackgroundColor))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.primary.opacity(isPressed || isTested ? 0.0 : 0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.02), radius: 1, x: 0, y: 1)
    }
}

// In-file KeyboardMonitor helper class definition
class KeyboardMonitor: ObservableObject {
    @Published var pressedKeys = Set<String>()
    @Published var testedKeys = Set<String>()
    
    private var localMonitor: Any?
    private var flagsMonitor: Any?
    
    func startMonitoring() {
        // Intercept normal key downs
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isDown: true)
            return nil // Consuming intercepts beep
        }
        
        // Intercept modifier flag alterations
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
            return event
        }
    }
    
    func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent, isDown: Bool) {
        let key = keyIdentifier(for: event.keyCode)
        if !key.isEmpty {
            DispatchQueue.main.async {
                self.pressedKeys.insert(key)
                self.testedKeys.insert(key)
                
                // Animate key lift shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    self.pressedKeys.remove(key)
                }
            }
        }
    }
    
    private func handleFlagsEvent(_ event: NSEvent) {
        let flags = event.modifierFlags
        let keyCode = event.keyCode
        
        let checkModifier = { (flag: NSEvent.ModifierFlags, key: String) in
            if flags.contains(flag) {
                DispatchQueue.main.async {
                    self.pressedKeys.insert(key)
                    self.testedKeys.insert(key)
                }
            } else {
                DispatchQueue.main.async {
                    self.pressedKeys.remove(key)
                }
            }
        }
        
        switch keyCode {
        case 56: checkModifier(.shift, "ShiftL")
        case 60: checkModifier(.shift, "ShiftR")
        case 59: checkModifier(.control, "CtrlL")
        case 62: checkModifier(.control, "CtrlR")
        case 58: checkModifier(.option, "OptL")
        case 61: checkModifier(.option, "OptR")
        case 55: checkModifier(.command, "CmdL")
        case 54: checkModifier(.command, "CmdR")
        case 57: checkModifier(.capsLock, "CapsLock")
        case 63: checkModifier(.function, "Fn")
        default: break
        }
    }
    
    private func keyIdentifier(for keyCode: UInt16) -> String {
        switch keyCode {
        // Numbers & Symbols Row
        case 50: return "`"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        case 27: return "-"
        case 24: return "="
        case 51: return "Delete"
            
        // Row 1 (QWERTY)
        case 48: return "Tab"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 17: return "T"
        case 16: return "Y"
        case 32: return "U"
        case 34: return "I"
        case 31: return "O"
        case 35: return "P"
        case 33: return "["
        case 30: return "]"
        case 42: return "\\"
            
        // Row 2 (ASDF)
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 41: return ";"
        case 39: return "'"
        case 36: return "Return"
            
        // Row 3 (ZXCV)
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 45: return "N"
        case 46: return "M"
        case 43: return ","
        case 47: return "."
        case 44: return "/"
            
        // Bottom Row
        case 49: return "Space"
            
        // Navigation / Arrows
        case 123: return "ArrowL"
        case 124: return "ArrowR"
        case 125: return "ArrowD"
        case 126: return "ArrowU"
            
        // Function keys
        case 53: return "Esc"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
            
        default: return ""
        }
    }
}

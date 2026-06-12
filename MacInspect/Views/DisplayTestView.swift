import SwiftUI

struct DisplayTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @State private var isTesting = false
    @State private var showResultConfirmation = false
    @State private var selectedResult: TestStatus? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Pixel Test")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Scan the screen for dead pixels, stuck pixels, or backlight bleeding.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            if !showResultConfirmation {
                // Intro Card
                VStack(spacing: 20) {
                    Image(systemName: "macpro.gen3.server")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                        .padding(.bottom, 8)
                    
                    Text("Fullscreen Color Diagnostics")
                        .font(.headline)
                    
                    Text("The test will display solid screens of colors in this order:\nBlack ➔ White ➔ Red ➔ Green ➔ Blue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Button(action: {
                        startFullscreenTest()
                    }) {
                        Text("Start Fullscreen Test")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(32)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: 480)
            } else {
                // Confirmation screen
                VStack(spacing: 20) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    
                    Text("Inspection Results")
                        .font(.headline)
                    
                    Text("Did you observe any dead/stuck pixels or screen backlight bleeding during the fullscreen color sequence?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                        .lineSpacing(4)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            submitResult(status: .failed, score: 0, details: "Issues detected by user (dead pixels or bleeding).")
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Yes, Issues Detected")
                            }
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            submitResult(status: .passed, score: 15, details: "No display issues detected.")
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("No, Screen is Clear")
                            }
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(32)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: 480)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button("Skip Test") {
                    manager.skipModule(id: "display")
                }
                .buttonStyle(.bordered)
                .disabled(showResultConfirmation)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var windowController = FullscreenWindowController()
    
    private func startFullscreenTest() {
        isTesting = true
        let view = ColorCycleView(onFinish: {
            self.isTesting = false
            self.windowController.close()
            DispatchQueue.main.async {
                self.showResultConfirmation = true
            }
        })
        windowController.show(content: AnyView(view), onClose: {
            self.isTesting = false
        })
    }
    
    private func submitResult(status: TestStatus, score: Int, details: String) {
        manager.updateModuleStatus(id: "display", status: status, score: score, details: details)
        manager.advanceToNext(after: "display")
    }
}

// Fullscreen solid color cycler
struct ColorCycleView: View {
    var onFinish: () -> Void
    
    @State private var colorIndex = 0
    private let colors: [(Color, String)] = [
        (.black, "Black"),
        (.white, "White"),
        (.red, "Red"),
        (.green, "Green"),
        (.blue, "Blue")
    ]
    
    var body: some View {
        ZStack {
            colors[colorIndex].0
                .edgesIgnoringSafeArea(.all)
            
            // HUD controls overlay (fades on hover)
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    Button(action: {
                        if colorIndex > 0 {
                            colorIndex -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(colorIndex == 0)
                    
                    VStack(spacing: 4) {
                        Text("\(colors[colorIndex].1) Test Screen")
                            .font(.headline)
                            .foregroundColor(colors[colorIndex].1 == "White" ? .black : .white)
                        Text("Step \(colorIndex + 1) of \(colors.count)")
                            .font(.caption)
                            .foregroundColor(colors[colorIndex].1 == "White" ? .secondary : .white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(colors[colorIndex].1 == "White" ? Color.white.opacity(0.8) : Color.black.opacity(0.6))
                    .cornerRadius(8)
                    
                    Button(action: {
                        if colorIndex < colors.count - 1 {
                            colorIndex += 1
                        } else {
                            onFinish()
                        }
                    }) {
                        Image(systemName: colorIndex == colors.count - 1 ? "checkmark" : "chevron.right")
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 32)
            }
        }

        .onAppear {
            // Give window keyboard focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Focus handling is automatic on borderless window key activation
            }
        }
        .onKeyDown { event in
            switch event.keyCode {
            case 124, 49: // Right arrow or Space
                if colorIndex < colors.count - 1 {
                    colorIndex += 1
                } else {
                    onFinish()
                }
            case 123: // Left arrow
                if colorIndex > 0 {
                    colorIndex -= 1
                }
            case 53: // Escape
                onFinish()
            default:
                break
            }
        }
    }
}

// Custom Fullscreen Window Controller
class FullscreenWindowController: NSObject, NSWindowDelegate {
    var window: NSWindow?
    var onClose: (() -> Void)?
    
    func show(content: AnyView, onClose: @escaping () -> Void) {
        self.onClose = onClose
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let newWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless, .fullScreen],
            backing: .buffered,
            defer: false
        )
        newWindow.level = .mainMenu + 1
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.contentView = NSHostingView(rootView: content)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.delegate = self
        self.window = newWindow
        
        // Hide dock and menu bar during fullscreen test
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
    }
    
    func close() {
        window?.close()
        window = nil
        NSApp.presentationOptions = []
        onClose?()
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.presentationOptions = []
        onClose?()
    }
}

// SwiftUI Helper to capture key downs
extension View {
    func onKeyDown(action: @escaping (NSEvent) -> Void) -> some View {
        background(
            KeyDownHelper(action: action)
        )
    }
}

struct KeyDownHelper: NSViewRepresentable {
    var action: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyViewWrapper()
        view.action = action
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? KeyViewWrapper)?.action = action
    }
}

class KeyViewWrapper: NSView {
    var action: ((NSEvent) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        action?(event)
    }
}

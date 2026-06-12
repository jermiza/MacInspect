import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var manager: InspectionManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Premium Logo icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "macpro.gen3")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("MacInspect")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Run a complete Mac hardware inspection in a few minutes.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            
            // Overview Cards
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comprehensive Diagnosis")
                            .font(.headline)
                        Text("Verifies input fields, display clarity, acoustic feedback, sensor feeds, and I/O chips.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hardware Analytics")
                            .font(.headline)
                        Text("Queries battery health metrics, cycle counts, system profiles, and CPU types.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Professional Grading")
                            .font(.headline)
                        Text("Generates a clear scoring index and compiles a vector PDF report for print and distribution.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .frame(maxWidth: 480)
            .padding(.vertical, 12)
            
            Button(action: {
                withAnimation {
                    manager.startInspection()
                }
            }) {
                Text("Start Inspection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.blue.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Compatible with Apple Silicon & Intel Macs")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

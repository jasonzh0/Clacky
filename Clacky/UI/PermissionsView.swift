import SwiftUI

struct PermissionsView: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 44))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title3)
                .bold()

            Text(subtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            HStack {
                if !controller.hasAccessibilityPermission {
                    Button("Open System Settings") {
                        controller.requestAccessibilityPermission()
                    }
                    .keyboardShortcut(.defaultAction)
                    Button("Recheck") { controller.refreshPermissionStatus() }
                } else if controller.needsRestart {
                    Button("Restart Clacky") {
                        controller.relaunchApp()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconName: String {
        if !controller.hasAccessibilityPermission { return "exclamationmark.shield.fill" }
        if controller.needsRestart { return "arrow.clockwise.circle.fill" }
        return "checkmark.shield.fill"
    }

    private var iconColor: Color {
        if !controller.hasAccessibilityPermission { return .orange }
        if controller.needsRestart { return .blue }
        return .green
    }

    private var title: String {
        if !controller.hasAccessibilityPermission { return "Accessibility access required" }
        if controller.needsRestart { return "Restart Clacky to finish" }
        return "Accessibility access granted"
    }

    private var subtitle: String {
        if !controller.hasAccessibilityPermission {
            return "Clacky needs Accessibility access to hear your keystrokes. Your keystrokes are not recorded or stored."
        }
        if controller.needsRestart {
            return "macOS keeps the old permission state for already-running apps. A quick restart picks up the change."
        }
        return "Clacky can listen for keystrokes globally."
    }
}

import SwiftUI

/// Colorblind-friendly status indicator: shape encodes state, color reinforces it.
/// Success/completed = blue circle, failed = red square, in progress = orange, default = gray.
struct StatusIndicator: View {
    let status: String
    var size: CGFloat = 8

    var body: some View {
        shape.fill(color).frame(width: size, height: size)
    }

    private var shape: AnyShape {
        status.lowercased() == "failed" ? AnyShape(Rectangle()) : AnyShape(Circle())
    }

    private var color: Color {
        switch status.lowercased() {
        case "success", "completed": .blue
        case "failed": .red
        case "in progress", "in_progress": .orange
        default: .gray
        }
    }
}

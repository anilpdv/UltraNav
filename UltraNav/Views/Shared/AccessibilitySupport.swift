import SwiftUI

private struct MinimumWatchTapTarget: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

extension View {
    func minimumWatchTapTarget() -> some View {
        modifier(MinimumWatchTapTarget())
    }
}

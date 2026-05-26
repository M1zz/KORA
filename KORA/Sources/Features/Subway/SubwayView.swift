import SwiftUI

/// Single-screen subway navigation host. Wraps the navigator in a
/// NavigationStack so the language picker can live in the standard
/// trailing toolbar slot.
struct SubwayView: View {
    var body: some View {
        NavigationStack {
            SubwayNavigatorView()
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SubwayView()
}

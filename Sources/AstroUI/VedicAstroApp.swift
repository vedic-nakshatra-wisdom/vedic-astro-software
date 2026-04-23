import SwiftUI
import AstroCore

@main
struct VedicAstroApp: App {
    var body: some Scene {
        WindowGroup {
            ChartInputView()
                .frame(minWidth: 520, minHeight: 700)
        }
        .windowResizability(.contentMinSize)
    }
}

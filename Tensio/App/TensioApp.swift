import SwiftData
import SwiftUI

@main
struct TensioApp: App {
    private let modelContainer: ModelContainer = {
        do {
            let launchArguments = ProcessInfo.processInfo.arguments
            let usesInMemoryStore = launchArguments.contains("UITestUseInMemoryStore")
            return try TensioModelContainer.make(inMemory: usesInMemoryStore)
        } catch {
            fatalError("Failed to create Tensio model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}

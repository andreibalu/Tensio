import SwiftData
import SwiftUI

@main
struct TensioApp: App {
    private let launchConfiguration = TensioLaunchConfiguration(
        arguments: ProcessInfo.processInfo.arguments
    )
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
                .applyTestDynamicTypeSize(launchConfiguration.dynamicTypeSize)
        }
        .modelContainer(modelContainer)
    }
}

struct TensioLaunchConfiguration {
    let dynamicTypeSize: DynamicTypeSize?

    init(arguments: [String]) {
        dynamicTypeSize = Self.dynamicTypeSize(for: arguments)
    }

    static func dynamicTypeSize(for arguments: [String]) -> DynamicTypeSize? {
        arguments.contains("UITestAccessibility3") ? .accessibility3 : nil
    }
}

private extension View {
    @ViewBuilder
    func applyTestDynamicTypeSize(_ dynamicTypeSize: DynamicTypeSize?) -> some View {
        if let dynamicTypeSize {
            self.dynamicTypeSize(dynamicTypeSize)
        } else {
            self
        }
    }
}

import SwiftData

enum TensioModelContainer {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            BPReadingRecord.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}

import Foundation
import SwiftData
import TensioCore

protocol ReadingSaving {
    func save(_ reading: BloodPressureReading, in modelContext: ModelContext) throws
}

struct SwiftDataReadingSaver: ReadingSaving {
    func save(_ reading: BloodPressureReading, in modelContext: ModelContext) throws {
        modelContext.insert(BPReadingRecord(reading: reading))
        try modelContext.save()
    }
}

struct FailingReadingSaver: ReadingSaving {
    let error: Error

    init(error: Error = CocoaError(.fileWriteUnknown)) {
        self.error = error
    }

    func save(_ reading: BloodPressureReading, in modelContext: ModelContext) throws {
        throw error
    }
}

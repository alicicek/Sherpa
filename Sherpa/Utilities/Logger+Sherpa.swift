import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sherpadaily.sherpa"

    static let startup = Logger(subsystem: subsystem, category: "Startup")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let habits = Logger(subsystem: subsystem, category: "Habits")
}

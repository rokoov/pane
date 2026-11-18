import os

// Debug messages only, read them with: log stream --level debug --predicate 'subsystem == "com.rokoov.pane"'
extension Logger {
    private static let subsystem = "com.rokoov.pane"

    static let gesture = Logger(subsystem: subsystem, category: "gesture")
    static let window = Logger(subsystem: subsystem, category: "window")
}

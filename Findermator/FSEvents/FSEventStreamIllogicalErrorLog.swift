//
//  FSEventsIllogicalErrorLog.swift
//  FSEvents
//
//  Created by Hoon H. on 2016/10/02.
//
//

/// An error that is very unlikely to happen if this library code is properly written.
///
public struct FSEventsIllogicalErrorLog {
    public var code: FSEventsCriticalErrorCode
    public var message: String?
    init(code: FSEventsCriticalErrorCode) {
        self.code = code
    }
    init(code: FSEventsCriticalErrorCode, message: String) {
        self.code = code
        self.message = message
    }
    func cast() {
        FSEventsIllogicalErrorLog.handler(self)
    }

    /// Can be called at any thread.
    public static var handler: (FSEventsIllogicalErrorLog) -> () = { assert(false, "FSEvents: \($0)") }
}

public enum FSEventsCriticalErrorCode {
    case missingContextRawPointerValue
    case unexpectedPathValueType
    case unmatchedEventParameterCounts
}

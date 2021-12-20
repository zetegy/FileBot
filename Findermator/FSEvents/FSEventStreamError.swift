//
//  FSEventsError.swift
//  FSEvents
//
//  Created by Hoon H. on 2016/10/02.
//
//

public struct FSEventsError: Error {
    public var code: FSEventsErrorCode
    public var message: String?
    init(code: FSEventsErrorCode) {
        self.code = code
    }
    init(code: FSEventsErrorCode, message: String) {
        self.code = code
        self.message = message
    }
}

public enum FSEventsErrorCode {
    case cannotCreateStream
    case cannotStartStream
}

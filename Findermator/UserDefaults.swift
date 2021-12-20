//
//  UserDefaults.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Foundation

@propertyWrapper
struct Storage<T> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            // Set value to UserDefaults
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct CodableUserDefault<T: Codable> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            if let json = UserDefaults.standard.data(forKey: key),
               let object = try? JSONDecoder().decode(T.self, from: json) {
                return object
            }
            return defaultValue
        }
        set {
            if let json = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(json, forKey: key)
            }
            
        }
    }
}

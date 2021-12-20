//
//  Rule.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Foundation
import AppKit

enum EventType: String, CaseIterable, RawRepresentable, Codable {
    case newFilesAdded = "New files only"
    case newOrExistingFiles = "New and existing files"
    
    var description: String {
        switch self {
        case .newFilesAdded: return "Process all new files added to the directory after the automation is activated. Existing files won't be affected."
        case .newOrExistingFiles: return "After the automation is activated, all existing files will be processed according to the rules you specify. In addition, all new files will be processed while the automation is active."
        }
    }
    
    var changesContentsImmediately: Bool {
        switch self {
        case .newFilesAdded:
            return false
        case .newOrExistingFiles:
            return true
        }
    }
}

enum AuxViewType {
    case none
    case folderPicker
    case subfolderPicker
    case textField
    case tokenField
    case richTextField
    case fileSizePicker
    case datePicker
}

enum AuxViewComposition {
    case simple
    case range
}

enum PredicateDataType {
    case string
    case tokenString
    case fileSize
    case date
    
    var auxViewType: AuxViewType {
        switch self {
        case .string:
            return .textField
        case .tokenString:
            return .tokenField
        case .fileSize:
            return .fileSizePicker
        case .date:
            return .datePicker
        }
    }
}

enum MovingDate: String, CaseIterable, RawRepresentable, Codable {
    case now = "now"
    case minutesAgo = "minutes ago"
    case hoursAgo = "hours ago"
    case daysAgo = "days ago"
    case monthsAgo = "months ago"
    case yearsAgo = "years ago"
    case exact = "exact date"
    
    static var separator: Character = ";"
    
    func dates(from floatParameter: Double) -> [Date] {
        var minDate = Date()
        var maxDate = Date()
        
        switch self {
        case .now:
            return [minDate]
        case .minutesAgo:
            let tmp = minDate.addingTimeInterval(-floatParameter * 60)
            let cmp = Calendar.current.component(.second, from: tmp)
            let minComponents = DateComponents(second: -cmp)
            let maxComponents = DateComponents(second: 59 - cmp)
            minDate = Calendar.current.date(byAdding: minComponents, to: tmp) ?? tmp
            maxDate = Calendar.current.date(byAdding: maxComponents, to: tmp) ?? tmp
        case .hoursAgo:
            let tmp = minDate.addingTimeInterval(-floatParameter * 3600)
            let cmp = Calendar.current.component(.minute, from: tmp)
            let minComponents = DateComponents(minute: -cmp)
            let maxComponents = DateComponents(minute: 59 - cmp)
            minDate = Calendar.current.date(byAdding: minComponents, to: tmp) ?? tmp
            maxDate = Calendar.current.date(byAdding: maxComponents, to: tmp) ?? tmp
        case .daysAgo:
            let tmp = minDate.addingTimeInterval(-floatParameter * 3600 * 24)
            minDate = tmp.startOfDay
            maxDate = tmp.endOfDay
        case .monthsAgo:
            let tmp = minDate.addingTimeInterval(-floatParameter * 3600 * 24 * 30)
            minDate = tmp.startOfMonth
            maxDate = tmp.endOfMonth
        case .yearsAgo:
            let tmp = minDate.addingTimeInterval(-floatParameter * 3600 * 24 * 365)
            minDate = tmp.startOfYear
            maxDate = tmp.endOfYear
        case .exact:
            return [Date(timeIntervalSince1970: floatParameter)]
        }
        
        print("Dates output: \(minDate) \(maxDate)")
        return [minDate, maxDate]
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)

        return  calendar.date(from: components)!
    }
    
    var startOfYear: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: self)

        return  calendar.date(from: components)!
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfYear)!
    }

    func isMonday() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday == 2
    }
}

enum Predicate: String, CaseIterable, RawRepresentable, Codable, IconSupporting {
    case name = "Name"
    case kind = "Kind"
    case fileSize = "File Size"
    case dateCreated = "Date Created"
    case dateModified = "Date Modified"
//    case dateAdded = "Date Added"
    
    var dataType: PredicateDataType {
        switch self {
        case .name:
            return .string
        case .kind:
            return .tokenString
        case .fileSize:
            return .fileSize
        case .dateCreated, .dateModified:
            return .date
        }
    }
    
    @available(macOS 11.0, *)
    var icon: NSImage {
        switch self {
        case .name:
            return NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: nil) ?? NSImage()
        case .kind:
            return NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: nil) ?? NSImage()
        case .fileSize:
            return NSImage(systemSymbolName: "ruler", accessibilityDescription: nil) ?? NSImage()
        case .dateCreated, .dateModified:
            return NSImage(systemSymbolName: "calendar", accessibilityDescription: nil) ?? NSImage()
        }
    }
    
    public func matches(file fileURL: URL,
                        with predicateType: PredicateType,
                        predicateContents: [String]) -> MatchResult {
        
        let fileName = fileURL.lastPathComponent
        let pathExtension = fileURL.pathExtension
        
        switch self {
        case .name:
            return predicateType.matches(string: fileName, with: predicateContents)
        case .kind:
            return predicateType.matches(string: pathExtension.lowercased(), with: predicateContents.map { $0.lowercased() })
        case .fileSize:
            var fileSize: Double

            do {
                let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let tempSize = attr[FileAttributeKey.size] as! UInt64
                fileSize = Double(tempSize)

                let dict = attr as NSDictionary
                fileSize = Double(dict.fileSize())
                return predicateType.matches(fileSize: fileSize, with: predicateContents)
            } catch {
                print("Error: \(error)")
                return MatchResult(isMatched: false)
            }
        case .dateModified, .dateCreated:
            do {
                var attrKey: FileAttributeKey
                switch self {
                case .dateCreated:
                    attrKey = .creationDate
                case .dateModified:
                    attrKey = .modificationDate
                default:
                    attrKey = .modificationDate
                }
                
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                guard let date = fileAttributes[attrKey] as? Date else {
                    return MatchResult(isMatched: false)
                }
                print("\(self.rawValue): \(date)")
                
                return predicateType.matches(date: date, with: predicateContents)
            } catch let error {
                print("Error getting file modification attribute date: \(error.localizedDescription)")
                return MatchResult(isMatched: false)
            }
        }

    }
}

struct MatchResult {
    var isMatched: Bool
    var contents: [String] = []
}

enum PredicateType: String, CaseIterable, RawRepresentable, Codable {
    case literal = "is"
    case anyOf = "is any of"
    case isNot = "is not"
    case isAnything = "is anything"
    case contains = "contains"
    case greaterThan = "is greater than"
    case lessThan = "is less than"
    case between = "is between"
    case unknown = "<error>"
    
    var composition: AuxViewComposition {
        switch self {
        case .between:
            return .range
        default:
            return .simple
        }
    }
    
    var dataTypes: [PredicateDataType] {
        switch self {
        case .anyOf:
            return [.tokenString]
        case .literal, .isNot, .isAnything:
            return [.string, .fileSize, .date]
        case .contains:
            return [.string, .tokenString]
        case .greaterThan, .lessThan, .between:
            return [.fileSize, .date]
        default:
            return []
        }
    }
    
    func isIncluded(inPredicate predicate: Predicate) -> Bool {
        return dataTypes.contains(predicate.dataType)
    }
    
    public func matches(string lhs: String, with predicateContents: [String]) -> MatchResult {
        guard let firstContents = predicateContents.first else { return MatchResult(isMatched: false) }
        
        let possibleContents = firstContents.split(separator: ",").map { String($0).trimmingCharacters(in: .illegalCharacters).trimmingCharacters(in: .whitespacesAndNewlines) }

        if possibleContents.count > 0 {
            for rhs in possibleContents {
                if _matches(string: lhs, with: rhs) {
                    return MatchResult(isMatched: true, contents: [rhs])
                }
            }
        } else {
            return MatchResult(isMatched: _matches(string: lhs, with: firstContents), contents: predicateContents)
        }
        
        return MatchResult(isMatched: false)
    }
    
    public func matches(fileSize lhs: Double, with predicateContents: [String]) -> MatchResult {
        let intPredicate = predicateContents.map({ Double($0) ?? 0 })
        return MatchResult(isMatched: _matches(fileSize: lhs, with: intPredicate), contents: predicateContents)
    }
    
    public func matches(date lhs: Date, with predicateContents: [String]) -> MatchResult {
        return MatchResult(isMatched: _matches(date: lhs, with: predicateContents), contents: predicateContents)
    }
    
    private func _matches(string lhs: String, with predicateContents: String) -> Bool {
        switch self {
        case .literal, .anyOf:
            return lhs == predicateContents
        case .isNot:
            return lhs != predicateContents
        case .contains:
            return lhs.contains(predicateContents)
        case .isAnything:
            return true
        default:
            return false
        }
    }
    
    private func _matches(fileSize lhs: Double, with predicateContents: [Double]) -> Bool {
        switch self {
        case .literal, .anyOf:
            return lhs == predicateContents[0]
        case .isNot:
            return lhs != predicateContents[0]
        case .greaterThan:
            return lhs > predicateContents[0]
        case .lessThan:
            return lhs < predicateContents[0]
        case .between:
            if let min = predicateContents.min(), let max = predicateContents.max() {
                return lhs >= min && lhs <= max
            }
            return false
        case .isAnything:
            return true
        default:
            return false
        }
    }
    
    private func _matches(date lhs: Date, with predicateContents: [String]) -> Bool {
        
        var parsedParams: [Date] = []
        for content in predicateContents {
            let values = Array(content.split(separator: MovingDate.separator))
            if values.count == 2 {
                
                if let movingDate = MovingDate.allCases.first(where: { $0.rawValue == values[1] }),
                    let double = Double(values[0]) {
                    
                    let dateCollection = movingDate.dates(from: double)
                    parsedParams.append(contentsOf: dateCollection)
                }
                
            }
        }
        
        if parsedParams.isEmpty {
            return false
        }
        
        switch self {
        case .literal, .anyOf:
            return parsedParams.filter { $0 == lhs }.count > 0
        case .isNot:
            return parsedParams.filter { $0 != lhs }.count > 0
        case .greaterThan:
            return lhs > parsedParams.max()!
        case .lessThan:
            return lhs < parsedParams.min()!
        case .between:
            if let min = parsedParams.min(), let max = parsedParams.max() {
                return lhs >= min && lhs <= max
            }
            return false
        case .isAnything:
            return true
        default:
            return false
        }
    }
}

protocol IconSupporting {
    @available(macOS 11.0, *)
    var icon: NSImage { get }
}

enum ScriptPredicate: String, CaseIterable, RawRepresentable, Codable, IconSupporting {
    case filename = "filename"
    case kind = "kind"
    case directoryPath = "path"
    case year = "year"
    case month = "month"
    case monthName = "monthName"
    case weekday = "weekday"
    case day = "day"
    case date = "date"
    
    func apply(to fileURL: URL) -> String {
        switch self {
        case .filename:
            return fileURL.deletingPathExtension().lastPathComponent
        case .kind:
            return fileURL.pathExtension
        case .directoryPath:
            return fileURL.deletingLastPathComponent().path
        case .year:
            return String(Calendar.current.component(.year, from: Date()))
        case .month:
            return String(Calendar.current.component(.month, from: Date()))
        case .day:
            return String(Calendar.current.component(.day, from: Date()))
        case .date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            return dateFormatter.string(from: Date())
        case .monthName:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            return dateFormatter.string(from: Date())
        case .weekday:
            return String(Calendar.current.component(.weekday, from: Date()))
        }
    }
    
    var humanReadableName: String {
        switch self {
        case .filename:
            return "Name of File"
        case .kind:
            return "File Kind"
        case .directoryPath:
            return "Path for Containing Folder"
        case .year:
            return "Current Year"
        case .month:
            return "Current Month Number"
        case .monthName:
            return "Current Month Name"
        case .day:
            return "Current Day Number"
        case .date:
            return "Current Date"
        case .weekday:
            return "Current Weekday"
        }
    }
    
    @available(macOS 11.0, *)
    var icon: NSImage {
        switch self {
        case .filename:
            return NSImage(systemSymbolName: "doc", accessibilityDescription: humanReadableName)!
        case .kind:
            return NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: humanReadableName)!
        case .directoryPath:
            return NSImage(systemSymbolName: "folder", accessibilityDescription: humanReadableName)!
        case .year, .month, .day, .date, .monthName, .weekday:
            return NSImage(systemSymbolName: "calendar", accessibilityDescription: humanReadableName)!
        }
    }
}

enum ScriptModifier: String, CaseIterable, RawRepresentable, Codable {
    case uppercase = "upper"
    case lowercase = "lower"
    case reverse = "reverse"
    case trim = "trim"
    case capitalize = "format"
    case length = "length"
    
    func apply(to string: String) -> String {
        switch self {
        case .uppercase:
            return string.uppercased()
        case .lowercase:
            return string.lowercased()
        case .reverse:
            return String(string.reversed())
        case .trim:
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case .capitalize:
            return string.capitalized
        case .length:
            return String(string.count)
        }
    }
    
    var humanReadableName: String {
        switch self {
        case .uppercase:
            return "To Uppercase"
        case .lowercase:
            return "To Lowercase"
        case .reverse:
            return "Reversed Characters"
        case .trim:
            return "Clear Trailing Whitespace"
        case .capitalize:
            return "Format and Capitalize"
        case .length:
            return "Number of Characters"
        }
    }
    
    @available(macOS 11.0, *)
    var icon: NSImage {
        switch self {
        case .uppercase:
            return NSImage(systemSymbolName: "textformat.size.larger", accessibilityDescription: humanReadableName)!
        case .lowercase:
            return NSImage(systemSymbolName: "textformat.abc", accessibilityDescription: humanReadableName)!
        case .reverse:
            return NSImage(systemSymbolName: "shuffle", accessibilityDescription: humanReadableName)!
        case .trim:
            return NSImage(systemSymbolName: "scissors", accessibilityDescription: humanReadableName)!
        case .capitalize:
            return NSImage(systemSymbolName: "textformat", accessibilityDescription: humanReadableName)!
        case .length:
            return NSImage(systemSymbolName: "ruler", accessibilityDescription: humanReadableName)!
        }
    }
}

enum PredicateAction: String, CaseIterable, RawRepresentable, Codable, IconSupporting {
    case moveTo = "move to folder"
    case delete = "move to trash"
    case rename = "rename"
    case moveToNamed = "move to subfolder"
    case moveToCustom = "move to folder (custom)"
    case open = "open the file"
    case doNothing = "do nothing"
    
    var auxViewType: AuxViewType {
        switch self {
        case .moveTo:
            return .folderPicker
//        case .moveToNamed:
//            return .subfolderPicker
        case .delete, .open, .doNothing:
            return .none
        case .rename, .moveToCustom, .moveToNamed:
            return .richTextField
        }
    }
    
    @available(macOS 11.0, *)
    var icon: NSImage {
        switch self {
        
        case .moveTo, .moveToNamed:
            return NSImage(systemSymbolName: "folder", accessibilityDescription: nil) ?? NSImage()
        case .delete:
            return NSImage(systemSymbolName: "trash", accessibilityDescription: nil) ?? NSImage()
        case .rename:
            return NSImage(systemSymbolName: "pencil", accessibilityDescription: nil) ?? NSImage()
        case .moveToCustom:
            return NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil) ?? NSImage()
        case .open:
            return NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: nil) ?? NSImage()
        case .doNothing:
            return NSImage(systemSymbolName: "xmark", accessibilityDescription: nil) ?? NSImage()
        }
    }
    
    static var scriptMatchPattern = "\\$\\{([\\w]+|-)\\}(?>\\.([a-zA-Z]+))?"
    
    public func execute(forFile fileURL: URL, actionContents: String, satPredicateContents: [String]) {
        
        var actionContents = actionContents
        
        do {
            let regex = try NSRegularExpression(pattern: PredicateAction.scriptMatchPattern)
            let results = regex.matches(in: actionContents,
                                        range: NSRange(actionContents.startIndex..., in: actionContents))
            
            var nsContents = actionContents as NSString
            
            for result in results.reversed() {
                
                if result.numberOfRanges <= 1 || result.range(at: 0).length == 0 { continue }
                
                let mainMatchString = nsContents.substring(with: result.range(at: 1)) // ${...}
                
                if var index = Int(mainMatchString),
                    index <= satPredicateContents.count { // if it's a number, it refers to a sat predicate
                    
                    index -= 1 // decrement to get 0-based
                    
                    var replacementString = satPredicateContents[index]
                    
                    if result.numberOfRanges > 2,
                        let modifier = ScriptModifier(rawValue: nsContents.substring(with: result.range(at: 2))) { // we have a modifier
                        
                        replacementString = modifier.apply(to: replacementString)
                    }
                    
                    nsContents = nsContents.replacingCharacters(in: result.range, with: replacementString) as NSString

                } else if let predicate = ScriptPredicate(rawValue: mainMatchString) { // custom script predicate ${...}
                    
                    var replacementString = predicate.apply(to: fileURL)
                    
                    if result.numberOfRanges > 2, result.range(at: 2).length > 0,
                        let modifier = ScriptModifier(rawValue: nsContents.substring(with: result.range(at: 2))) { // we have a modifier
                        
                        replacementString = modifier.apply(to: replacementString)
                    }
                    
                    nsContents = nsContents.replacingCharacters(in: result.range, with: replacementString) as NSString
                }
                
            }
            
            actionContents = nsContents as String
            
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
        }
        
        do {
            switch self {
            case .moveToNamed, .moveTo, .moveToCustom:
                var dirURL: URL
                if self == .moveToNamed {
                    dirURL = fileURL.deletingLastPathComponent().appendingPathComponent(actionContents, isDirectory: true)
                    (NSApp.delegate as? AppDelegate)?.ignoredURLs.insert(dirURL)
                } else {
                    dirURL = URL(fileURLWithPath: actionContents)
                }
                
                if !FileManager.default.fileExists(atPath: dirURL.path) {
                    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                }
                var newURL = dirURL.appendingPathComponent(fileURL.lastPathComponent)
                
                var i = 0
                while FileManager.default.fileExists(atPath: newURL.path) {
                    i += 1
                    let newFileName = fileURL.deletingPathExtension().lastPathComponent + " \(i)"
                    newURL = dirURL.appendingPathComponent(newFileName).appendingPathExtension(fileURL.pathExtension)
                }
                
                print(newURL)
                (NSApp.delegate as? AppDelegate)?.ignoredURLs.insert(newURL)
                try FileManager.default.moveItem(at: fileURL, to: newURL)
            case .delete:
                try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            case .rename:
                let dirURL = fileURL.deletingPathExtension().deletingLastPathComponent()
                let newURL = dirURL.appendingPathComponent(actionContents).appendingPathExtension(fileURL.pathExtension)
                var finalURL = newURL
                var i = 0
                while FileManager.default.fileExists(atPath: finalURL.path) {
                    i += 1
                    let newFileName = newURL.deletingPathExtension().lastPathComponent + " \(i)"
                    finalURL = dirURL.appendingPathComponent(newFileName).appendingPathExtension(newURL.pathExtension)
                }
                
                (NSApp.delegate as? AppDelegate)?.ignoredURLs.insert(finalURL)
                try FileManager.default.moveItem(at: fileURL, to: finalURL)
            case .open:
                NSWorkspace.shared.open(fileURL)
            case .doNothing:
                return
            }
        } catch {
            print(error)
        }
    }
}

struct ImportableMonitoredDirectory: Codable {
    var name: String
    var description: String
    var iconName: String
}

struct MonitoredDirectoryExported: Codable {
    var content: MonitoredDirectory
    var version: String
    var description: String
}

enum SubfolderDepth: String, Codable, CaseIterable {
    case none = "never"
    case level1 = "up to 1 level"
    case level2 = "up to 2 levels"
    case level3 = "up to 3 levels"
    case level4 = "up to 4 levels"
    case level5 = "up to 5 levels"
    
    var allowedLevelDifference: Int {
        switch self {
        case .none:
            return 0
        case .level1:
            return 1
        case .level2:
            return 2
        case .level3:
            return 3
        case .level4:
            return 4
        case .level5:
            return 5
        }
    }
}

struct MonitoredDirectory: Identifiable, Codable {
    
    var id = UUID()
    var name: String
    var url: URL
    var isActive: Bool
    var includesSubfolders: SubfolderDepth
    var when: EventType
    var version: Int = 1
    var rules: [Rule]
    
    var hasValidURL: Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case isActive
        case includesSubfolders
        case when
        case version
        case rules
    }
    
    init(id: UUID = UUID(), name: String, url: URL, isActive: Bool, includesSubfolders: SubfolderDepth, when: EventType, rules: [Rule]) {
        self.id = id
        self.name = name
        self.url = url
        self.isActive = isActive
        self.includesSubfolders = includesSubfolders
        self.when = when
        self.rules = rules
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        url = try values.decode(URL.self, forKey: .url)
        isActive = try values.decode(Bool.self, forKey: .isActive)
        if let includesSubfoldersBool = try? values.decode(Bool.self, forKey: .includesSubfolders) {
            includesSubfolders = includesSubfoldersBool ? .level1 : .none
        } else {
            includesSubfolders = try values.decode(SubfolderDepth.self, forKey: .includesSubfolders)
        }
        when = try values.decode(EventType.self, forKey: .when)
        version = (try? values.decode(Int.self, forKey: .version)) ?? 1
        rules = try values.decode([Rule].self, forKey: .rules)
    }
}

struct Rule: Identifiable, Codable {
    var id = UUID()
    var predicates: [RulePredicate]
    var action: RuleAction
}

struct RulePredicate: Identifiable, Codable {
    var id = UUID()
    var predicateIndex: Int
    var predicateTypeIndex: Int
    var predicateContents: [String]
}

struct RuleAction: Identifiable, Codable {
    var id = UUID()
    var actionIndex: Int
    var actionContents: String
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

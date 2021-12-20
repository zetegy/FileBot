//
//  RuleView.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Cocoa

protocol StringRepresentableView: NSView {
    var string: String { get set }
}

protocol WrappedPredicateView: NSStackView {
    var value: [String] { get set }
}

final class SinglePredicateView: NSStackView, WrappedPredicateView {
    
    var value: [String] {
        get { [view.string] }
        set { view.string = newValue[0] }
    }
    
    var view: StringRepresentableView
    
    init(view: StringRepresentableView) {
        self.view = view
        
        super.init(frame: .zero)
        
        self.orientation = .horizontal
        self.alignment = .centerY
        
        self.addArrangedSubview(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

final class RangePredicateView: NSStackView, WrappedPredicateView {
    
    var value: [String] {
        get { _views.map { $0.string } }
        set {
            for (i, view) in _views.enumerated() {
                view.string = newValue[i]
            }
        }
    }
    
    var _views: [StringRepresentableView]
    
    init(views: [StringRepresentableView]) {
        self._views = views
        
        super.init(frame: .zero)
        
        self.orientation = .horizontal
        self.alignment = .centerY
        
        if views.count >= 2 {
            self.addArrangedSubview(views[0])
            self.addArrangedSubview(NSTextField(labelWithString: "and"))
            self.addArrangedSubview(views[1])
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension NSTextField: StringRepresentableView {
    var string: String {
        get { stringValue }
        set { stringValue = newValue }
    }
}

class RuleView: NSView, NibLoadable {
    
    public var addOrdered: ((RuleView) -> (Void))?
    public var removeOrdered: ((RuleView) -> (Void))?
    
    public var numberOfPredicates: Int {
        var predicates = 0
        for subview in containerStackView.arrangedSubviews {
            if subview is PredicateView {
                predicates += 1
            }
        }
        return predicates
    }
    
    public var rule: Rule {
        get {
            var predicates = [RulePredicate]()
            for subview in containerStackView.arrangedSubviews {
                if let predView = subview as? PredicateView {
                    predicates.append(predView.predicate)
                }
            }
            let action = RuleAction(actionIndex: actionButton.selectedTag(), actionContents: customActionView?.string ?? "")
            return Rule(predicates: predicates, action: action)
        }
        
        set {
            let rule = newValue
            
            for predicate in rule.predicates.reversed() {
                let predicateView = newPredicateView
                predicateView.predicate = predicate
                containerStackView.insertArrangedSubview(predicateView, at: 0)
            }
            
            actionButton.selectItem(withTag: rule.action.actionIndex)
            actionChanged(self)
            customActionView?.string = rule.action.actionContents
            
        }
    }
    
    private weak var customActionView: StringRepresentableView?

    @IBOutlet weak var actionButton: NSPopUpButton!
    @IBOutlet weak var actionStackView: NSStackView!
    
    @IBOutlet weak var deleteRuleButton: NSButton!
    @IBOutlet weak var addRuleButton: NSButton!
    @IBOutlet weak var containerStackView: NSStackView!
    
    @IBOutlet weak var accessorySuperview: NSView!
    @IBOutlet weak var accessorySubview: NSView!
    
    static private var customActionViewIndex = 2
    
    static func _auxView(for type: AuxViewType, in container: RuleView) -> StringRepresentableView? {
        var view: StringRepresentableView?
        switch type {
        case .none:
            return nil
        case .folderPicker:
            view = FileSelectButton()
        case .textField:
            view = WideTextField()
        case .fileSizePicker:
            view = FileSizePicker()
        case .subfolderPicker:
            let picker = SubfolderPicker(with: container)
            view = picker
        case .richTextField:
            let textView = AutocompletingTextView()
            textView.setUp(with: container)
            view = textView
        case .datePicker:
            let datePicker = RelativeDatePicker()
            view = datePicker
        case .tokenField:
            view = WideTokenField()
        }
        return view
    }
    
    static func auxView(for type: AuxViewType, composition: AuxViewComposition, in container: RuleView) -> WrappedPredicateView? {
        switch composition {
        case .simple:
            if let view = _auxView(for: type, in: container) {
                return SinglePredicateView(view: view)
            }
        case .range:
            if let view1 = _auxView(for: type, in: container), let view2 = _auxView(for: type, in: container) {
                return RangePredicateView(views: [view1, view2])
            }
        }
        return nil
    }
    
    @IBAction func actionChanged(_ sender: Any) {
        if let customActionView = customActionView {
            actionStackView.removeArrangedSubview(customActionView)
            customActionView.removeFromSuperview()
            self.customActionView = nil
        }

        let action = PredicateAction.allCases[actionButton.selectedTag()].auxViewType

        if let view = RuleView._auxView(for: action, in: self) {
            actionStackView.insertArrangedSubview(view, at: RuleView.customActionViewIndex)
            customActionView = view
        }
    }
    
    @IBAction func minusClicked(_ sender: Any) {
        removeOrdered?(self)
    }
    
    @IBAction func plusClicked(_ sender: Any) {
        addOrdered?(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accessorySuperview.wantsLayer = true
        accessorySuperview.layer?.cornerRadius = 14
        accessorySuperview.layer?.borderColor = NSColor.quaternaryLabelColor.cgColor
        accessorySuperview.layer?.borderWidth = 2
        
        accessorySubview.wantsLayer = true
        accessorySubview.layer?.cornerRadius = 12
        accessorySubview.layer?.borderColor = NSColor.quaternaryLabelColor.cgColor
        accessorySubview.layer?.borderWidth = 2
        
        actionButton.menu = NSMenu.create(fromEnum: PredicateAction.self)
        
        actionChanged(self)
        
    }
    
    override func layout() {
        super.layout()
        
        if !(containerStackView.arrangedSubviews.first is PredicateView) {
            containerStackView.insertArrangedSubview(newPredicateView, at: 0)
        }
    }
    
    private lazy var addPredicateOrdered: ((PredicateView) -> (Void)) = {
        return { [weak self] view in
            guard let self = self else { return }
            var index = self.containerStackView.arrangedSubviews.firstIndex(where: { $0 === view }) ?? self.containerStackView.arrangedSubviews.count - 1
            index += 1
            
            let predicateView = self.newPredicateView
            if index > 0 {
                predicateView.ifLabel.stringValue = "and"
            }
            self.containerStackView.insertArrangedSubview(predicateView, at: index)
        }
    }()
    
    private lazy var removePredicateOrdered: ((PredicateView) -> (Void)) = {
        return { [weak self] view in
            guard let self = self else { return }
            self.containerStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }()
    
    private var newPredicateView: PredicateView {
        let predicateView = PredicateView.createFromNib()!
        predicateView.container = self
        predicateView.addOrdered = addPredicateOrdered
        predicateView.removeOrdered = removePredicateOrdered
        
        return predicateView
    }
    
}

final class WideTokenField: NSTokenField {
    init(width: CGFloat = 180) {
        super.init(frame: .zero)
        self.bezelStyle = .roundedBezel
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(equalToConstant: width)
        addConstraint(constraint)
        constraint.isActive = true
        
        self.tokenizingCharacterSet = CharacterSet(charactersIn: ",")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WideTextField: NSTextField {
    init(width: CGFloat = 180) {
        super.init(frame: .zero)
        self.bezelStyle = .roundedBezel
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(equalToConstant: width)
        addConstraint(constraint)
        constraint.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FileSelectButton: NSButton, StringRepresentableView {
    
    var string: String = "" {
        didSet {
            self.title = URL(fileURLWithPath: string, isDirectory: true).lastPathComponent
            print(URL(fileURLWithPath: string, isDirectory: true).lastPathComponent)
        }
    }
    
    @objc func folderSelectionClicked() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.prompt = "Use this folder"
        
        openPanel.beginSheetModal(for: self.window!) { [unowned self] result in
            
            if result == NSApplication.ModalResponse.OK {
                let url = openPanel.url
                string = url?.path ?? ""
                self.title = url?.lastPathComponent ?? "Folder"
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.setButtonType(.momentaryPushIn)
        self.bezelStyle = .rounded
        title = "Choose Folder..."
        target = self
        action = #selector(folderSelectionClicked)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FileSizePicker: NSStackView, StringRepresentableView {
    
    enum SizeType: String, CaseIterable {
        case byte = "B"
        case kb = "KB"
        case mb = "MB"
        case gb = "GB"
        case tb = "TB"
    }
    
    var string: String {
        get {
            guard let value = Double(textField.stringValue) else { return "" }
            var returnValue = Double()
            let type = SizeType.allCases[sizePicker.selectedTag()]
            switch type {
            case .byte:
                returnValue = value
            case .kb:
                returnValue = value * 1024
            case .mb:
                returnValue = value * 1024 * 1024
            case .gb:
                returnValue = value * 1024 * 1024 * 1024
            case .tb:
                returnValue = value * 1024 * 1024 * 1024 * 1024
            }
            return String(returnValue)
        }
        
        set {
            if var value = Double(newValue) {
                var type: SizeType = .byte
                while value >= 1024 || value < 1 {
                    value = value / 1024
                    type = type.next()
                }
                
                sizePicker.selectItem(withTitle: type.rawValue)
                
                let formatter = NumberFormatter()
                formatter.minimumFractionDigits = 0
                formatter.hasThousandSeparators = false
                formatter.usesGroupingSeparator = false
                formatter.numberStyle = .decimal
                textField.stringValue = formatter.string(from: Double(value) as NSNumber)!
            }
        }
    }
    
    lazy var textField: NSTextField = {
        WideTextField(width: 60)
    }()
    
    lazy var sizePicker: NSPopUpButton = {
        let button = NSPopUpButton()
        button.menu = NSMenu.create(fromEnum: SizeType.self)
        button.selectItem(at: sizePickerIndex)
        return button
    }()
    
    @Storage(key: "FileSizePickerDefaultIndex", defaultValue: 1)
    var sizePickerIndex: Int
    
    init() {
        super.init(frame: .zero)
        
        orientation = .horizontal
        spacing = 8.0
        
        addArrangedSubview(textField)
        addArrangedSubview(sizePicker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RelativeDatePicker: NSStackView, StringRepresentableView {
    
    var string: String {
        get {
            let type = MovingDate.allCases[sizePicker.selectedTag()]
            var value: Double
            
            switch type {
            case .now:
                value = 0
            case .exact:
                value = datePicker.dateValue.timeIntervalSince1970
            default:
                value = Double(textField.stringValue) ?? 0
            }

            return "\(value)\(MovingDate.separator)\(type.rawValue)"
        }
        
        set {
            let values = Array(newValue.split(separator: MovingDate.separator))
            if values.count == 2 {
                sizePicker.selectItem(withTitle: String(values[1]))
                textField.stringValue = String(values[0])
                if let type = MovingDate(rawValue: String(values[1])), type == .exact {
                    datePicker.dateValue = Date(timeIntervalSince1970: Double(String(values[0]))!)
                }
                didSelectDate(sizePicker)
            }
            
        }
    }
    
    lazy var textField: NSTextField = {
        let tf = WideTextField(width: 60)
        tf.formatter = NumberFormatter()
        return tf
    }()
    
    lazy var sizePicker: NSPopUpButton = {
        let button = NSPopUpButton()
        button.menu = NSMenu.create(fromEnum: MovingDate.self)
        button.selectItem(at: datePickerIndex)
        button.target = self
        button.action = #selector(didSelectDate(_:))
        return button
    }()
    
    lazy var datePicker: NSDatePicker = {
        let button = NSDatePicker()
        return button
    }()
    
    @Storage(key: "RelDatePickerDefaultIndex", defaultValue: 1)
    var datePickerIndex: Int
    
    @objc func didSelectDate(_ sender: NSPopUpButton) {

        let type = MovingDate.allCases[sizePicker.selectedTag() >= 0 ? sizePicker.selectedTag() : 0]
        switch type {
        case .now:
            if arrangedSubviews.contains(textField) {
                removeArrangedSubview(textField)
                textField.removeFromSuperview()
            }
            if arrangedSubviews.contains(datePicker) {
                removeArrangedSubview(datePicker)
                datePicker.removeFromSuperview()
            }
        case .minutesAgo, .hoursAgo, .daysAgo, .monthsAgo, .yearsAgo:
            if arrangedSubviews.contains(datePicker) {
                removeArrangedSubview(datePicker)
                datePicker.removeFromSuperview()
            }
            if !arrangedSubviews.contains(textField) {
                insertArrangedSubview(textField, at: 0)
            }
        case .exact:
            if arrangedSubviews.contains(textField) {
                removeArrangedSubview(textField)
                textField.removeFromSuperview()
            }
            if !arrangedSubviews.contains(datePicker) {
                insertArrangedSubview(datePicker, at: 0)
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        orientation = .horizontal
        spacing = 8.0
        
        addArrangedSubview(textField)
        addArrangedSubview(sizePicker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Double {
    var decimalPlaces: Int {
        let decimals = String(self).split(separator: ".")[1]
        return decimals == "0" ? 0 : decimals.count
    }
}

extension CaseIterable where Self: Equatable {
    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}

extension Double {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

final class SubfolderPicker: NSStackView, StringRepresentableView {
    
    private weak var container: RuleView?
    
    var string: String {
        get {
            var baseURL = URL(fileURLWithPath: filePicker.string)
            baseURL = baseURL.appendingPathComponent(textField.string, isDirectory: true)
            return baseURL.path
        }
        
        set {
            let folderName = URL(fileURLWithPath: newValue)
            let lastPathComponent = folderName.lastPathComponent
            let baseFolder = folderName.deletingLastPathComponent()
            textField.textStorage?.setAttributedString(NSAttributedString(string: lastPathComponent))
            filePicker.string = baseFolder.path
        }
    }
    
    lazy var textField: AutocompletingTextView = {
        let view = AutocompletingTextView()
        view.setUp(with: container)
        return view
    }()
    
    lazy var filePicker: FileSelectButton = {
        FileSelectButton()
    }()
    
    @Storage(key: "FileSizePickerDefaultIndex", defaultValue: 1)
    var sizePickerIndex: Int
    
    init(with container: RuleView?) {
        super.init(frame: .zero)
        
        self.container = container
        
        orientation = .horizontal
        spacing = 8.0
        
        addArrangedSubview(textField)
        addArrangedSubview(NSTextField(labelWithString: "in folder"))
        addArrangedSubview(filePicker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AutocompletingTextView: PZAutocompleteTextView, StringRepresentableView {
    
    var detailHeightConstraint: NSLayoutConstraint!
    
    private weak var container: RuleView?
    private var queuedImage: NSImage?
    
    public func setUp(with container: RuleView?) {
        self.container = container
        self.delegate = self
        self.autocompleteDelegate = self
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 4
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.textContainerInset = NSSize(width: 6, height: 4)
        
        let constraint = widthAnchor.constraint(equalToConstant: 180)
        addConstraint(constraint)
        constraint.isActive = true
        
        detailHeightConstraint = heightAnchor.constraint(equalToConstant: 0)
        addConstraint(detailHeightConstraint)
        detailHeightConstraint.isActive = true
        
        font = .systemFont(ofSize: 13)
        textColor = .labelColor
        
        updateHeight()
    }
    
    func processSyntax() {
        let attributedString = NSMutableAttributedString(string: self.string)
        attributedString.addAttributes([.font: NSFont.systemFont(ofSize: 13)], range: NSRange(location: 0, length: attributedString.length))
        
        do {
            let regex = try NSRegularExpression(pattern: PredicateAction.scriptMatchPattern)
            let results = regex.matches(in: self.string,
                                        range: NSRange(self.string.startIndex..., in: self.string))
            
            for result in results.reversed() {
                
                for i in 0..<result.numberOfRanges {
                    if result.range(at: i).length == 0 { continue }
                    
                    var attributes = [NSAttributedString.Key: Any]()
                    switch i {
                    case 0:
                        attributes = [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]
                    case 1:
                        attributes = [.foregroundColor: NSColor.systemBlue]
                    case 2:
                        attributes = [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)]
                    default:
                        break
                    }
                    
                    attributedString.addAttributes(attributes, range: result.range(at: i))
                }
                
            }
            
            self.textStorage?.setAttributedString(attributedString)
            
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
        }
    }
    
    override var intrinsicContentSize: NSSize {
        guard let manager = textContainer?.layoutManager else {
            return .zero
        }
        
        manager.ensureLayout(for: textContainer!)
        
        var size = manager.usedRect(for: textContainer!).size
        size.width += self.textContainerInset.width * 2
        size.height += self.textContainerInset.height * 2
        
        return size
    }
    
    override func insertNewline(_ sender: Any?) {
        
    }
    
    override func layout() {
        super.layout()
        
        processSyntax()
        updateHeight()
    }
    
    private func updateHeight() {
        detailHeightConstraint.constant = max(25, intrinsicContentSize.height)
    }
    
}

extension AutocompletingTextView: NSTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        processSyntax()
        updateHeight()
    }

}

extension AutocompletingTextView: PZAutocompleteTableViewDelegate {
    
    func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>?) -> [String] {
        
        if let stringToMatch = textView.textStorage?.mutableString.substring(with: charRange),
            stringToMatch[0] == "$" {
            
            var predictions = [String]()
            
            let matchStringSplit = stringToMatch.split(separator: ".")
            if matchStringSplit.count > 1 || stringToMatch.last == "." {
                // Modifiers
                predictions = ScriptModifier.allCases.map { "\(matchStringSplit[0]).\($0.rawValue)" }
                if matchStringSplit.count > 1 {
                    predictions = predictions.filter { $0.contains(matchStringSplit[1]) }
                }
            } else if let container = container {
                // ScriptPredicates
                for predicate in ScriptPredicate.allCases {
                    predictions.append("${\(predicate.rawValue)}")
                }
                for i in 0..<container.numberOfPredicates {
                    predictions.append("${\(i + 1)}")
                }
            }
            
            return predictions
        }
        return []
    }
    
    func textView(_ textView: NSTextView!, labelForCompletion word: String!) -> String! {
        let matchStringSplit = word.split(separator: ".")
        if matchStringSplit.count == 1,
            let regex = try? NSRegularExpression(pattern: PredicateAction.scriptMatchPattern) {
            // predicates
            
            let results = regex.matches(in: word,
                                        range: NSRange(word.startIndex..., in: word))
            
            let nsContents = word as NSString
            
            for result in results.reversed() {
                
                if result.numberOfRanges <= 1 { continue }
                
                let mainMatchString = nsContents.substring(with: result.range(at: 1)) // ${...}
                
                if let index = Int(mainMatchString),
                    index <= (container?.numberOfPredicates ?? 1) { // if it's a number, it refers to a sat predicate
                    
                    if #available(macOS 11.0, *) {
                        queuedImage = NSImage(systemSymbolName: "curlybraces", accessibilityDescription: nil)
                    } else {
                        queuedImage = nil
                    }
                    return "Match for Condition #\(index)"

                } else if let predicate = ScriptPredicate(rawValue: mainMatchString) { // custom script predicate ${...}
                    
                    if #available(macOS 11.0, *) {
                        queuedImage = predicate.icon
                    } else {
                        queuedImage = nil
                    }
                    return predicate.humanReadableName
                }
                
            }
            
            
        } else if matchStringSplit.count > 1, let modifier = ScriptModifier(rawValue: String(matchStringSplit[1])) {
            // modifiers
            if #available(macOS 11.0, *) {
                queuedImage = modifier.icon
            } else {
                queuedImage = nil
            }
            return modifier.humanReadableName
        }
        
        queuedImage = nil
        return ""
    }
    
    func textView(_ textView: NSTextView!, imageForCompletion word: String!) -> NSImage! {
        return queuedImage ?? NSImage()
    }
}

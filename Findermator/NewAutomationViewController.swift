//
//  NewAutomationViewController.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Cocoa

extension NSMenu {
    static func create<T: RawRepresentable & CaseIterable>(fromEnum enumObject: T.Type,
                                                           includingItemWithRawValue include: ((String) -> (Bool)) = { _ in true }
    ) -> NSMenu where T.RawValue == (String) {
        
        
        let menu = NSMenu()
        for (i, enumItem) in enumObject.allCases.enumerated() {
            if include(enumItem.rawValue) {
                let menuItem = NSMenuItem(title: enumItem.rawValue, action: nil, keyEquivalent: "")
                menuItem.tag = i
                if #available(macOS 11.0, *),
                    let iconEnum = enumItem as? IconSupporting {
                    
                    menuItem.image = iconEnum.icon
                }
                menu.addItem(menuItem)
            }
        }
        return menu
    }
}

class NewAutomationViewController: NSViewController {
    
    public var isEditing = false
    public var uuid = UUID()
    
    private var folderURL: URL?
    
    private var newTargetHeight: CGFloat = 0
    private var currentAnimation: NSViewAnimation?
    private var animationDuration: CGFloat = 0

    @IBOutlet weak var automationNameField: NSTextField!
    
    @IBOutlet weak var folderButton: NSButton!
    
    @IBOutlet weak var whenPopupButton: NSPopUpButton!
    
    @IBOutlet weak var whenDecriptionLabel: NSTextField!
    
    @IBOutlet weak var rulesStackView: NSStackView!
    
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var createButton: NSButton!
    
    @IBOutlet weak var automateSubfoldersButton: NSPopUpButton!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func folderButtonClicked(_ sender: Any) {
        guard let window = self.view.window else { return }
        SecurityBookmarks.shared.openFolderSelection(from: window) { [weak self] url in
            guard let self = self, let selectedURL = url else { return }
            
            SecurityBookmarks.shared.saveBookmarksData()
            
            self.folderURL = selectedURL
            self.folderButton.title = selectedURL.lastPathComponent
        }
    }
    
    @IBAction func nameValueChanged(_ sender: Any) {
        view.window?.title = automationNameField.stringValue
    }
    
    @IBAction func whenValueChanged(_ sender: Any) {
        whenDecriptionLabel.stringValue = EventType.allCases[whenPopupButton.selectedTag()].description
    }
    
    @IBAction func automateSubfoldersChanged(_ sender: Any) {
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        view.window?.close()
    }
    
    @IBAction func createClicked(_ sender: Any) {
        let eventType = EventType.allCases[whenPopupButton.selectedTag()]
        
        if eventType.changesContentsImmediately {
            let alert = NSAlert()
            alert.messageText = "Activate this automation?"
            alert.informativeText = "This automation is configured to process existing files in the directory. When activated, it will permanently change the contents of the directory and may lead to data loss if misconfigured. You can always edit or activate this automation later."
            alert.addButton(withTitle: "No, don't activate yet")
            alert.addButton(withTitle: "Yes, create and activate")
            alert.addButton(withTitle: "Cancel")
            let modalResult = alert.runModal()

            switch modalResult {
            case .alertFirstButtonReturn:
                createConfirmed(false)
            case .alertSecondButtonReturn:
                createConfirmed(true)
            case .alertThirdButtonReturn:
                return
            default: break
            }
        } else {
            createConfirmed()
        }
        
    }
    
    func createConfirmed(_ isActivated: Bool = true) {
        
        guard let folderURL = folderURL else {
            let alert = NSAlert()
            alert.messageText = "Select a folder first"
            alert.informativeText = "You need to select which folder this automation would be applied to. Don't worry – you can always modify that, and the automation itself can be edited later."
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
            return
        }
        
        let automationName = automationNameField.stringValue
        
        guard !automationName.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Name your automation first"
            alert.informativeText = "This will help you identify it later. Something short but descriptive, like 'Sort Documents into Folders by Date' should suffice."
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
            return
        }
        
        var rules = [Rule]()
        for view in rulesStackView.arrangedSubviews {
            if let predicateView = view as? RuleView {
                rules.append(predicateView.rule)
            }
        }
        
        let directory = MonitoredDirectory(name: automationName,
                                           url: folderURL,
                                           isActive: isActivated,
                                           includesSubfolders: SubfolderDepth.allCases[automateSubfoldersButton.selectedTag()],
                                           when: EventType.allCases[whenPopupButton.selectedTag()],
                                           rules: rules)
        
        DirectoryListViewController.shared?.addDirectory(directory, atExistingId: isEditing ? uuid : nil)
        
        cancelClicked(self)
    }
    
    private lazy var addOrdered: ((RuleView) -> (Void)) = {
        return { [weak self] view in
            guard let self = self else { return }
            var index = self.rulesStackView.arrangedSubviews.firstIndex(where: { $0 === view }) ?? self.rulesStackView.arrangedSubviews.count - 1
            index += 1
            
            let predicateView = self.newRuleView
            self.rulesStackView.insertArrangedSubview(predicateView, at: index)
        }
    }()
    
    private lazy var removeOrdered: ((RuleView) -> (Void)) = {
        return { [weak self] view in
            guard let self = self else { return }
            self.rulesStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
            
            if let index = self.rulesStackView.arrangedSubviews.firstIndex(where: { type(of: $0) == RuleView.self }), index != NSNotFound {} else {
                self.addRuleView()
            }
            
        }
    }()
    
    private var newRuleView: RuleView {
        let predicateView = RuleView.createFromNib()!
        predicateView.addOrdered = addOrdered
        predicateView.removeOrdered = removeOrdered
        return predicateView
    }
    
    var delegate: AppDelegate {
        NSApp.delegate as! AppDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automateSubfoldersButton.menu = NSMenu.create(fromEnum: SubfolderDepth.self)
        whenPopupButton.menu = NSMenu.create(fromEnum: EventType.self)
        whenDecriptionLabel.stringValue = EventType.allCases.first!.description
        
        scrollView.documentView?.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: scrollView.documentView, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            
            self.view.window?.styleMask.remove(.resizable)
            
            if var windowFrame = self.view.window?.frame,
               var frame = self.scrollView.documentView?.frame,
               let visibleFrame = NSScreen.main?.visibleFrame {
                
                let duration = self.animationDuration
                if duration == 0 {
                    self.animationDuration = 0.3
                }
                
                let heightDelta = self.view.bounds.height - self.scrollView.bounds.height + 30
                
                frame.size.height += heightDelta
                frame.size.width = min(windowFrame.width, self.scrollView.fittingSize.width)
                frame.size.height = min(frame.height, visibleFrame.height)

                if self.scrollView.bounds.height > frame.height || frame.height > visibleFrame.height {
                    
                    frame.size.height -= 30
                    
                    NSAnimationContext.runAnimationGroup { [weak self] context in
                        context.duration = duration
                        context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                        context.allowsImplicitAnimation = true
                        
                        self?.scrollView.frame = frame
                    }
                }
                
                windowFrame.size = frame.size
                windowFrame.size.width = min(windowFrame.width, self.view.bounds.width)
                
                if windowFrame.height != self.newTargetHeight && !(self.currentAnimation?.isAnimating ?? false) {
                    
                    self.newTargetHeight = windowFrame.height
                    
                    let windowResize = [
                        NSViewAnimation.Key.target: self.view.window!,
                        NSViewAnimation.Key.endFrame: NSValue(rect: self.view.window!.frameRect(forContentRect: windowFrame))
                    ]

                    let animations = [windowResize]
                    let animation = NSViewAnimation(viewAnimations: animations)

                    animation.animationBlockingMode = .nonblocking
                    animation.animationCurve = .easeInOut
                    animation.duration = duration
                    animation.start()
                    
                    self.currentAnimation = animation
                    
                }
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if isEditing,
           let directory = delegate.directories.first(where: { $0.id == uuid }) {
            
            //populate
            automationNameField.stringValue = directory.name
            nameValueChanged(self)
            
            self.folderURL = directory.url
            folderButton.title = directory.url.lastPathComponent
            
            whenPopupButton.selectItem(withTitle: directory.when.rawValue)
            whenValueChanged(self)
            
            automateSubfoldersButton.selectItem(withTitle: directory.includesSubfolders.rawValue)
            automateSubfoldersChanged(self)
            
            for rule in directory.rules {
                let ruleView = newRuleView
                ruleView.rule = rule
                rulesStackView.addArrangedSubview(ruleView)
            }
            
            createButton.title = "Save"
            
        } else {
            addRuleView()
        }
    }
    
    func addRuleView() {
        let ruleView = newRuleView
        rulesStackView.addArrangedSubview(ruleView)
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: scrollView.documentView)
        
        super.viewDidDisappear()
    }
    
}

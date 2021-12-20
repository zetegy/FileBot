//
//  ViewController.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Cocoa

class DirectoryListViewController: NSViewController {
    
    static weak var shared: DirectoryListViewController?
    
    @CodableUserDefault("ImportableDirectories_v3", defaultValue: [
        ImportableMonitoredDirectory(
            name: "Move to Subfolders by File Type",
            description: "Every new file in the folder you select will be placed in a subfolder based on its type: for example, PNG, PDF, etc.",
            iconName: "square.grid.3x1.folder.badge.plus"
        ),
        ImportableMonitoredDirectory(
            name: "Organize by File Size",
            description: "Files will be placed into subfolders based on their size. Size thresholds can be modified.",
            iconName: "doc.viewfinder"
        ),
        ImportableMonitoredDirectory(
            name: "Unzip Automatically",
            description: "Unzips zip, rar, and 7z archives automatically when they're added to the specified folder.",
            iconName: "doc.zipper"
        ),
        
        
    ])
    var importableDirectories: [ImportableMonitoredDirectory]
    
    @Storage(key: "FirstDisclosure", defaultValue: true)
    private var isAutomationSectionDisclosed: Bool
    
    @Storage(key: "SecondDisclosure", defaultValue: true)
    private var isSuggestionSectionDisclosed: Bool
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var overlayView: NSVisualEffectView!
    
    var delegate: AppDelegate {
        NSApp.delegate as! AppDelegate
    }
    
    private lazy var directoryDidChangeActiveStatus: ((UUID, Bool) -> (Void)) = {
        return { [weak self] id, isActive in
            guard let self = self else { return }
            
            if let row = self.delegate.directories.firstIndex(where: { $0.id == id }),
                row != NSNotFound {
                
                self.delegate.directories[row].isActive = isActive
                
                self.tableView.reloadData(forRowIndexes: self.rows(for: .myAutomations), columnIndexes: IndexSet(integer: 0))
                
                let newDirectory = self.delegate.directories[row]
                if isActive && newDirectory.when == .newOrExistingFiles {
                    (NSApp.delegate as? AppDelegate)?.processActivation(for: newDirectory)
                }
            }
            
        }
    }()
    
    private lazy var directoryRequestedEdit: ((UUID) -> (Void)) = {
        return { [weak self] id in
            guard let self = self else { return }
            
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let wc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "NewAutomationWindowController")) as? NSWindowController else { return }
            
            if let vc = wc.contentViewController as? NewAutomationViewController {
                vc.isEditing = true
                vc.uuid = id
                self.presentAsModalWindow(vc)
            }
            
        }
    }()
    
    public func addDirectory(_ newDirectory: MonitoredDirectory, atExistingId uuid: UUID? = nil) {
        
        if let existingId = uuid {
            
            if let row = self.delegate.directories.firstIndex(where: { $0.id == existingId }),
               row != NSNotFound {
                
                self.delegate.directories[row] = newDirectory
                
                self.tableView.reloadData(forRowIndexes: rows(for: .myAutomations), columnIndexes: IndexSet(integer: 0))
            }
            
        } else {
            delegate.directories.append(newDirectory)
            tableView.insertRows(at: IndexSet(integer: rows(for: .myAutomations).last!), withAnimation: .slideDown)
        }
        
        delegate.resetMonitors()
        
        if newDirectory.when == .newOrExistingFiles {
            (NSApp.delegate as? AppDelegate)?.processActivation(for: newDirectory)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menu = NSMenu()
        menu.delegate = self
        
        tableView.menu = menu

        DirectoryListViewController.shared = self
        
        delegate.resetMonitors()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func processHalt(_ isPaused: Bool) {
        guard let viewToAnimate = overlayView else { return }
        if isPaused {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                viewToAnimate.animator().isHidden = false
            }
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                viewToAnimate.isHidden = true
            }
        }
    }
    
    @IBAction func resumeHaltPressed(_ sender: Any) {
        (self.view.window?.windowController as? MainWindowController)?.toggleHalt()
    }
    
    func reloadInformation(for directory: MonitoredDirectory) {
        tableView.reloadData()
    }
    
    @objc private func tableViewExportItemClicked(_ sender: AnyObject) {
        let index = index(from: tableView.clickedRow)
        
        guard tableView.clickedRow >= 0, index.section == .myAutomations else { return }
        
        let item = delegate.directories[index.row]

        FileExporter().exportFile(with: item)
    }
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        let index = index(from: tableView.clickedRow)
        
        guard tableView.clickedRow >= 0, index.section == .myAutomations else { return }
        
        let item = delegate.directories[index.row]

        directoryRequestedEdit(item.id)
    }

    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        let index = index(from: tableView.clickedRow)
        let row = rows(for: .myAutomations).min()!
        
        guard tableView.clickedRow >= 0, index.section == .myAutomations else { return }

        delegate.directories.remove(at: index.row)

        tableView.removeRows(at: IndexSet(integer: row + index.row), withAnimation: .slideUp)
        
        delegate.resetMonitors()
    }
    
    enum Section: Int {
        case myAutomationsHeading = 0
        case myAutomations
        case suggestionsHeading
        case suggestions
    }
    
    struct Index {
        var section: Section
        var row: Int
    }
    
    var expandedSections: [Int] {
        [1, delegate.directories.count, 1, importableDirectories.count]
    }
    
    var sections: [Int] {
        var sections = expandedSections
        if !isAutomationSectionDisclosed {
            sections[1] = 0
        }
        if !isSuggestionSectionDisclosed {
            sections[3] = 0
        }
        return sections
    }
    
    func rows(for section: Section) -> IndexSet {
        let sectionsCount = expandedSections
        var index = 0
        for (i, sectionCount) in sectionsCount.enumerated() {
            if i == section.rawValue {
                return IndexSet(integersIn: index..<(index + sectionCount))
            }
            index += sectionCount
        }
        return IndexSet()
    }
    
    func index(from row: Int) -> Index {
        let sectionsCount = sections
        var index = 0
        for (i, section) in sectionsCount.enumerated() {
            if row >= index && row < index + section {
                return Index(section: Section(rawValue: i)!, row: row - index)
            }
            index += section
        }
        return Index(section: Section(rawValue: 0)!, row: 0)
    }

}

extension DirectoryListViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let index = index(from: tableView.clickedRow)
        
        if index.section == .myAutomations {
            menu.addItem(NSMenuItem(title: "Export", action: #selector(tableViewExportItemClicked(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Edit", action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        }
        
    }
}

extension DirectoryListViewController: NSTableViewDelegate {
    
}

extension DirectoryListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sections.reduce(0, +)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let index = index(from: row)
        
        switch index.section {
        case .myAutomationsHeading, .suggestionsHeading:
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeadingItem"), owner: self) as? HeadingCellView else { return nil }
            
            switch index.section {
            case .myAutomationsHeading:
                cell.headingLabel.stringValue = "My Automations"
                cell.disclosureButton.state = isAutomationSectionDisclosed ? .on : .off
                cell.disclosureAction = { [weak self] isDisclosed in
                    guard let self = self else { return }
                    self.isAutomationSectionDisclosed = isDisclosed
                    if isDisclosed {
                        self.tableView.insertRows(at: self.rows(for: .myAutomations), withAnimation: .slideDown)
                    } else {
                        self.tableView.removeRows(at: self.rows(for: .myAutomations), withAnimation: .slideUp)
                    }
                }
            case .suggestionsHeading:
                cell.headingLabel.stringValue = "Suggestions"
                cell.disclosureButton.state = isSuggestionSectionDisclosed ? .on : .off
                cell.disclosureAction = { [weak self] isDisclosed in
                    guard let self = self else { return }
                    self.isSuggestionSectionDisclosed = isDisclosed
                    if isDisclosed {
                        self.tableView.insertRows(at: self.rows(for: .suggestions), withAnimation: .slideDown)
                    } else {
                        self.tableView.removeRows(at: self.rows(for: .suggestions), withAnimation: .slideUp)
                    }
                }
            default: break
            }
            
            return cell
        case .myAutomations:
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Item"), owner: self) as? DirectoryListItemCellView else { return nil }
            
            let data = delegate.directories[index.row]
            let hasValidURL = data.hasValidURL
            
            var subtitleText = String()
            var icon = NSImage()
            
            cell.id = data.id
            cell.directoryDidChangeActiveStatus = directoryDidChangeActiveStatus
            cell.directoryRequestedEdit = directoryRequestedEdit
            
            cell.titleLabel.stringValue = data.name
            
            cell.activitySwitch.state = data.isActive ? .on : .off
            cell.activitySwitch.isEnabled = hasValidURL
            
            if hasValidURL {
                subtitleText = "\(data.isActive ? "Active" : "Inactive")"
                subtitleText += ", in \(data.url.lastPathComponent)"
                cell.subtitleLabel.textColor = .labelColor
                
                icon = NSWorkspace.shared.icon(forFile: data.url.path)
            } else {
                subtitleText = "\(data.url.lastPathComponent) was moved or deleted. Edit the automation to reenable."
                cell.subtitleLabel.textColor = .systemRed
                
                if #available(macOS 11.0, *) {
                    icon = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")!
                } else {
                    // Fallback on earlier versions
                }
            }
            
            cell.iconView.image = icon
            cell.subtitleLabel.stringValue = subtitleText
            
            return cell
        case .suggestions:
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImportItem"), owner: self) as? DirectoryListItemCellView else { return nil }
            
            let data = importableDirectories[index.row]
            
//            cell.id = data.id
            cell.directoryDidChangeActiveStatus = directoryDidChangeActiveStatus
            cell.directoryRequestedEdit = { _ in
                if let url = Bundle.main.url(forResource: data.name, withExtension: "auto") {
                    FileExporter().importFile(at: url)
                }
            }
            
            cell.titleLabel.stringValue = data.name
            
            if #available(macOS 11.0, *) {
                let icon = NSImage(systemSymbolName: data.iconName, accessibilityDescription: data.name)
                
                cell.iconView.image = icon
                cell.iconView.imageScaling = .scaleProportionallyUpOrDown
            } else {
                // Fallback on earlier versions
            }
            
            if #available(macOS 12.0, *) {
                cell.iconView.symbolConfiguration = .init(hierarchicalColor: .controlAccentColor)
            } else {
                // Fallback on earlier versions
            }

            cell.subtitleLabel.stringValue = data.description
            
            return cell
        }
        
    }
}

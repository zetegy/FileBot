//
//  ImportConfirmationViewController.swift
//  FileBot
//
//  Created by Phil Zet on 11/26/21.
//

import Cocoa

class ImportConfirmationViewController: NSViewController {
    
    var directory: MonitoredDirectoryExported?
    private var folderURL: URL?
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    
    @IBOutlet weak var folderButton: NSButton!
    
    @IBOutlet weak var whenPopupButton: NSPopUpButton!
    
    @IBOutlet weak var whenDecriptionLabel: NSTextField!
    
    @IBAction func whenValueChanged(_ sender: Any) {
        whenDecriptionLabel.stringValue = EventType.allCases[whenPopupButton.selectedTag()].description
    }
    
    @IBAction func folderButtonClicked(_ sender: Any) {
        guard let window = self.view.window else { return }
        SecurityBookmarks.shared.openFolderSelection(from: window) { [weak self] url in
            guard let self = self, let selectedURL = url else { return }
            
            SecurityBookmarks.shared.saveBookmarksData()
            
            self.folderURL = selectedURL
            self.folderButton.title = selectedURL.lastPathComponent
        }
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        view.window?.close()
    }
    
    @IBAction func importClicked(_ sender: Any) {
        
        let eventType = EventType.allCases[whenPopupButton.selectedTag()]
        directory?.content.when = eventType
        
        if eventType.changesContentsImmediately {
            let alert = NSAlert()
            alert.messageText = "Activate this automation?"
            alert.informativeText = "This automation is configured to process existing files in the directory. When activated, it will permanently change the contents of the directory and may lead to data loss if misconfigured. You can always edit or activate this automation later."
            alert.addButton(withTitle: "No, don't activate yet")
            alert.addButton(withTitle: "Yes, import and activate")
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
        guard var directory = directory?.content,
              let folderURL = folderURL else {
                  let alert = NSAlert()
                  alert.messageText = "Select a folder first"
                  alert.informativeText = "You need to select which folder this automation would be applied to. Don't worry – you can always modify that, and the automation itself can be edited later. If someone shared this automation with you, the original creator won't see this information."
                  alert.addButton(withTitle: "OK")
                  _ = alert.runModal()
                  return
              }
        directory.isActive = isActivated
        directory.url = folderURL
        DirectoryListViewController.shared?.addDirectory(directory, atExistingId: nil)
        
        cancelClicked(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        whenPopupButton.menu = NSMenu.create(fromEnum: EventType.self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let directory = directory {
            titleLabel.stringValue = directory.content.name
            descriptionLabel.stringValue = directory.description
            whenPopupButton.selectItem(withTitle: directory.content.when.rawValue)
            whenValueChanged(self)
        } else {
            view.window?.close()
        }
    }
    
}

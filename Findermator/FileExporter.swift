//
//  FileExporter.swift
//  FileBot
//
//  Created by Phil Zet on 11/26/21.
//

import Foundation

struct FileExporter {
    func exportFile(with content: MonitoredDirectory) {
        let version: String = "v4"
        let description = getString(title: "Export Automation", question: "Give this automation a description, so that others can understand what it does in case you decide to share it. This is optional.", defaultValue: "")
        var item = MonitoredDirectoryExported(content: content, version: version, description: description)
        item.content.url = URL(fileURLWithPath: "")
        
        if let encodedItem = try? JSONEncoder().encode(item) {
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = false
            savePanel.nameFieldStringValue = "\(item.content.name).auto"
            savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
            savePanel.begin { (result) in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = savePanel.url {
                    try? encodedItem.write(to: url)
                }
            }
        }
    }
    
    func importFile(at url: URL) {
        guard let data = try? Data(contentsOf: url),
        let content = try? JSONDecoder().decode(MonitoredDirectoryExported.self, from: data) else {
            let alert = NSAlert()
            alert.messageText = "Failed to import this automation"
            alert.informativeText = "This could happen because it was created in an earlier (or later) version of the app, or if it was externally modified. If this automation was shared with you, ask the owner to export and share it again."
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
            return
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let wc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "ImportConfirmationWindowController")) as? NSWindowController else { return }
        
        if let vc = wc.contentViewController as? ImportConfirmationViewController {
            vc.directory = content
            
            if let window = wc.window {
                window.center()
                
                window.makeKeyAndOrderFront(nil)
                
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

        }
    }
    
    private func getString(title: String, question: String, defaultValue: String) -> String {
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
        msg.messageText = title
        msg.informativeText = question

        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.stringValue = defaultValue

        msg.accessoryView = txt
        let response: NSApplication.ModalResponse = msg.runModal()

        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
            return txt.stringValue
        } else {
            return ""
        }
    }
}

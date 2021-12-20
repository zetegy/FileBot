//
//  MainWindowController.swift
//  FileBot
//
//  Created by Phil Zet on 12/5/21.
//

import Cocoa
import PZHelpDesk

class MainWindowController: NSWindowController {
    
    var isForceDisabled: Bool {
        (NSApp.delegate as! AppDelegate).isForceDisabled
    }

    @IBAction func menuRequested(_ sender: Any) {
        if let toolbarItem = sender as? NSView {
            let menu = NSMenu()
            menu.addItem(withTitle: "\(isForceDisabled ? "Resume" : "Pause All") Automations", action: #selector(pauseAll(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Help", action: #selector(_helpRequested(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Quit FileBot", action: #selector(quitRequested(_:)), keyEquivalent: "")
            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: toolbarItem, with: nil)
        }
    }
    
    @objc private func quitRequested(_ sender: Any) {
        NSApp.terminate(sender)
    }
    
    @objc private func _helpRequested(_ sender: Any) {
        PZHelpDesk.shared.controller.present()
    }
    
    func toggleHalt() {
        pauseAll(self)
    }
    
    @objc private func pauseAll(_ sender: Any) {
        (NSApp.delegate as! AppDelegate).isForceDisabled.toggle()
        
        processHalt()
    }
    
    func processHalt() {
        (NSApp.delegate as? AppDelegate)?.directoryListVC?.processHalt(isForceDisabled)
        if isForceDisabled {
            (NSApp.delegate as? AppDelegate)?.stopMonitors()
        } else {
            (NSApp.delegate as? AppDelegate)?.resetMonitors()
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        processHalt()
    }

}

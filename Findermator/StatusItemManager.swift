//
//  StatusItemManager.swift
//  Findermator
//
//  Created by Phil Zet on 10/14/21.
//

import Cocoa

class StatusItemManager: NSObject {

    // MARK: - Properties
    
    static weak var shared: StatusItemManager?
    
    var statusItem: NSStatusItem?

    var windowController: NSWindowController?
    
    var isShown = false
    
    // MARK: - Init
    
    override func awakeFromNib() {
        super.awakeFromNib()

        initStatusItem()
        StatusItemManager.shared = self
    }
    
    // MARK: - Fileprivate Methods
    
    fileprivate func initStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let itemImage = NSImage(named: "StatusBar")
        itemImage?.isTemplate = true
        statusItem?.button?.image = itemImage
//        statusItem?.button?.title = "Automate Folders"
        
        statusItem?.button?.target = self
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self else { return event }
            
            if event.window == self.statusItem?.button?.window {
                self.showInitialVC()
                return nil
            }
            
            return event
        }
    }
    
    var desiredFrame: NSRect {
        guard let button = statusItem?.button, let frame = windowController?.contentViewController?.view.frame else { return .zero }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        let vc = NSViewController()
        let tempView = NSView(frame: frame)
        vc.view = tempView
        popover.contentViewController = vc
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        let rect = tempView.window!.convertToScreen(tempView.frame)
        popover.close()
        return rect
    }
        
    @objc public func showInitialVC() {
        
        if windowController == nil || !windowController!.isWindowLoaded {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "DirectoryListWindowController")) as? NSWindowController else { return }
            
            windowController = vc
        }
        
        let shouldOpen = !(windowController?.window?.isMainWindow ?? isShown)
        
        if shouldOpen {
            
            windowController?.window?.delegate = self
            windowController?.window?.setFrameOrigin(desiredFrame.origin)
            windowController?.window?.makeKeyAndOrderFront(nil)
            
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            windowController?.window?.isMovable = false
            windowController?.window?.hidesOnDeactivate = true
            
            isShown = true
            
            statusItem?.button?.highlight(true)
            
        } else {
            closeWindow()
        }
    }
    
    func closeWindow() {
        windowController?.window?.orderOut(NSApp)
        isShown = false
        statusItem?.button?.highlight(false)
    }
}

extension StatusItemManager: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        if !NSApp.isActive {
            closeWindow()
        }
    }
}

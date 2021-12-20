//
//  DirectoryListItemCellView.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Cocoa

class DirectoryListItemCellView: NSTableCellView {
    
    public var id = UUID()
    public var directoryDidChangeActiveStatus: ((UUID, Bool) -> (Void))?
    public var directoryRequestedEdit: ((UUID) -> (Void))?

    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var activitySwitch: NSSwitch!
    
    @IBOutlet weak var editButton: NSButton!
    
    private lazy var trackingArea = TrackingArea(
        for: self,
        options: [
            .mouseEnteredAndExited,
            .activeInActiveApp
        ]
    )
    
    @IBAction func switchDidChange(_ sender: Any) {
        directoryDidChangeActiveStatus?(id, activitySwitch.state == .on)
    }
    
    @IBAction func editClicked(_ sender: Any) {
        directoryRequestedEdit?(id)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingArea.update()
    }
    
    override func layoutSubtreeIfNeeded() {
        super.layoutSubtreeIfNeeded()
        
        updateTrackingAreas()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        editButton.alphaValue = 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        editButton.alphaValue = 0
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        let shouldUpdate = editButton.isHidden
        
        self.editButton.alphaValue = 1
        
        if shouldUpdate {
            updateTrackingAreas()
        }
        
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.editButton.animator().alphaValue = 0
        } completionHandler: {
        }
    }
    
}

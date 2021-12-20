//
//  HeadingCellView.swift
//  FileBot
//
//  Created by Phil Zet on 11/26/21.
//

import Cocoa

class HeadingCellView: NSTableCellView {
    
    var disclosureAction: ((Bool) -> Void)?

    @IBOutlet weak var headingLabel: NSTextField!
    @IBOutlet weak var disclosureButton: NSButton!
    
    @IBAction func disclosureButtonClicked(_ sender: Any) {
        disclosureAction?(disclosureButton.state == .on)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

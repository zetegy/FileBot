//
//  NSViewController+Helpers.swift
//  SampleProject
//
//  Created by Demian Turner on 16/06/2020.
//  Copyright © 2021 Demian Turner. All rights reserved.
//

import AppKit

extension NSViewController {
    public func setupAutoLayoutConstraining(child: NSView, to parent: NSView) {        
        child.translatesAutoresizingMaskIntoConstraints = false
        child.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
        child.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
        child.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: 10).isActive = true
    }
    
    public func makeButton() -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .circular
        button.focusRingType = .none
        return button
    }
}

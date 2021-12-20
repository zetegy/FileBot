//
//  ConstrainedWindow.swift
//  Findermator
//
//  Created by Phil Zet on 10/15/21.
//

import Cocoa

final class ConstrainedWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        var rect = super.constrainFrameRect(frameRect, to: screen)

        if let visibleFrame = NSScreen.main?.visibleFrame {
            rect = rect.intersection(visibleFrame)
        }
        return rect
    }
    
    override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval {
        0.2
    }
    
    override var isResizable: Bool {
        false
    }
    
    deinit {
        
    }
}


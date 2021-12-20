//
//  TrackingArea.swift
//  Findermator
//
//  Created by Phil Zet on 10/14/21.
//

import Cocoa

/**
Convenience class for adding a tracking area to a view.
```
final class HoverView: NSView {
    private lazy var trackingArea = TrackingArea(
        for: self,
        options: [
            .mouseEnteredAndExited,
            .activeInActiveApp
        ]
    )
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingArea.update()
    }
}
```
*/
final class TrackingArea {
    private weak var view: NSView?
    private let rect: CGRect
    private let options: NSTrackingArea.Options
    private var trackingArea: NSTrackingArea?

    /**
    - Parameters:
        - view: The view to add tracking to.
        - rect: The area inside the view to track. Defaults to the whole view (`view.bounds`).
    */
    init(
        for view: NSView,
        rect: CGRect? = nil,
        options: NSTrackingArea.Options = []
    ) {
        self.view = view
        self.rect = rect ?? view.bounds
        self.options = options
    }

    /**
    Updates the tracking area.
    - Note: This should be called in your `NSView#updateTrackingAreas()` method.
    */
    func update() {
        if let oldTrackingArea = trackingArea {
            view?.removeTrackingArea(oldTrackingArea)
        }

        let newTrackingArea = NSTrackingArea(
            rect: view!.bounds,
            options: options,
            owner: view,
            userInfo: nil
        )

        view?.addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }
}

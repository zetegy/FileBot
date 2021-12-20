//
//  OnboardingPageViewController.swift
//  Findermator
//
//  Created by Phil Zet on 10/16/21.
//

import Cocoa

class OnboardingPageViewController: NSViewController, NibLoadable {

    @IBOutlet weak var mainImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var additionalContentsStackView: NSStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    public func configured(withTitle titleString: String, descriptionString: String, image: NSImage? = nil, customViews: [NSView] = []) -> OnboardingPageViewController {
        
        titleLabel.stringValue = titleString
        descriptionLabel.stringValue = descriptionString
        mainImageView.image = image
        for view in customViews {
            additionalContentsStackView.addArrangedSubview(view)
        }
        
        return self
    }
    
}

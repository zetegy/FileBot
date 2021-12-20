//
//  HelpViewController.swift
//  FileBot
//
//  Created by Phil Zet on 10/24/21.
//

import Cocoa
import Down

class HelpViewController: NSViewController {
    
    var downView: DownView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "HELP", ofType: "md")
        let content = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        
        downView = try? DownView(frame: self.view.bounds, markdownString: content, templateBundle: Bundle.main) {
            self.view.addSubview(self.downView!)
        }
        
        downView?.autoresizingMask = [.width, .height]

    }
    
}

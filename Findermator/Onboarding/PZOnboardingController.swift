//
//  MyPageController.swift
//  OnboardingExample
//
//  Created by Demian Turner on 01/05/2020.
//  Copyright © 2021 Demian Turner. All rights reserved.
//

import AppKit
import DTPageControl

// for the view debugger
class DTOnboardingView: NSVisualEffectView {}
class DTPageView: NSView {}
class NSPageView: NSView {}

public class PZOnboardingController: NSViewController {
    
    public var pageController: NSPageController!
    public var config: DTOnboardingConfig
    public var pages: [NSViewController] = []
    
    private var pageControl: DTPageControl!
    
    //
    // MARK: - Lifecycle -
    //
    
    public init(with config: DTOnboardingConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    /// `NSPageController` must be a child VC for paging to work correctly
    public func setUp(for pages: [NSViewController]) {
        self.pages = pages
        
        let pageController = NSPageController()
        pageController.delegate = self

        addChild(pageController)
        self.pageController = pageController
    }
    
    public var nextItemButton: NSButton {
        let nextButton = NSButton(title: "Next", target: self, action: #selector(PZOnboardingController.navigateForward))
        return nextButton
    }
    
    public var doneButton: NSButton {
        let nextButton = NSButton(title: "Done", target: self, action: #selector(PZOnboardingController.done))
        return nextButton
    }
    
    public var spacer: NSView {
        return NSView()
    }
    
    @objc public func navigateForward() {
        pageController?.navigateForward(self)
    }
    
    @objc public func done() {
        StatusItemManager.shared?.showInitialVC()
        self.view.window?.close()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func maskImage(cornerRadius: CGFloat) -> NSImage {
        let edgeLength = 2.0 * cornerRadius + 1.0
        let maskImage = NSImage(size: NSSize(width: edgeLength, height: edgeLength), flipped: false) { rect in
            let bezierPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.black.set()
            bezierPath.fill()
            return true
        }
        maskImage.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        maskImage.resizingMode = .stretch
        return maskImage
    }
    
    public func runWindow() {
        let vc = self
        
        if let visualEffectView = vc.view as? NSVisualEffectView {
            visualEffectView.maskImage = maskImage(cornerRadius: 16)
        } else {
            vc.view.wantsLayer = true
            vc.view.layer?.masksToBounds = true
            vc.view.layer?.cornerRadius = 16
            vc.view.layer?.cornerCurve = .continuous
        }
        
        let myWindow = NSWindow(
            contentRect: .init(origin: .zero, size: NSSize(width: 500, height: 600)),
            styleMask: [.fullSizeContentView, .closable, .titled],
            backing: .buffered,
            defer: false
        )

        myWindow.titlebarAppearsTransparent = true
        myWindow.titleVisibility = .hidden
        myWindow.backgroundColor = .clear
        myWindow.isOpaque = false
        myWindow.isMovableByWindowBackground = true
        
        myWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        myWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
        myWindow.center()
        
        let onboardingWindowController = NSWindowController(window: myWindow)
        onboardingWindowController.contentViewController = vc
        
        myWindow.makeKeyAndOrderFront(nil)
        
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    private lazy var contentView: NSView = {
        let rect = NSRect(
            origin: .zero,
            size: NSSize(width: self.config.windowWidth, height: self.config.windowHeight)
        )
        let v = DTOnboardingView(frame: rect)
        v.blendingMode = .behindWindow
        v.material = .popover
        v.state = .active
                
        // back button
        let back = makeButton()
        back.target = pageController
        back.action = #selector(pageController.navigateBack(_:))
        back.image = NSImage(named: NSImage.Name("NSGoLeftTemplate"))
        v.addSubview(back)
        
        // layout
        back.translatesAutoresizingMaskIntoConstraints = false
        back.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
        back.leftAnchor.constraint(equalTo: v.leftAnchor, constant: 10).isActive = true
        
        // forward button
        let forward = makeButton()
        forward.target = pageController
        forward.action = #selector(pageController.navigateForward(_:))
        forward.image = NSImage(named: NSImage.Name("NSGoRightTemplate"))
        v.addSubview(forward)
        
        // layout
        forward.translatesAutoresizingMaskIntoConstraints = false
        forward.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
        forward.rightAnchor.constraint(equalTo: v.rightAnchor, constant: -10).isActive = true

        return v
    }()

    public override func loadView() {
       view = contentView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        
        let pageView = NSPageView(frame: .zero)
        view.addSubview(pageView)
        setupAutoLayoutConstraining(child: pageView, to: view)
        
        pageController.view = pageView
        
        // page identifiers
        pageController.arrangedObjects = pages.indices
            .map { $0 }
            .map { $0 + 1 }
            .map { String($0) }
        pageController.transitionStyle = config.pageTransitionStyle
        
        setupPageControl()
        
        pageController.navigateForward(self)
        pageController.navigateBack(self)
    }
    
    //
    // MARK: - DTPageControl -
    //
    
    private func setupPageControl() {
        pageControl = DTPageControl()
        pageControl.numberOfPages = pages.count

        view.addSubview(pageControl)
        
        // layout
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.widthAnchor.constraint(equalToConstant: CGFloat(config.pageControlWidth)).isActive = true
        pageControl.heightAnchor.constraint(equalToConstant: CGFloat(config.pageControlHeight)).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -CGFloat(config.pageControlVerticalDistanceFromBottom)).isActive = true
    }
}

//
// MARK: - NSPageControllerDelegate -
//

extension PZOnboardingController: NSPageControllerDelegate {
    // move pages above page control
    public func pageController(_ pageController: NSPageController, frameFor object: Any?) -> NSRect {
        return NSMakeRect(0, 10, CGFloat(config.windowWidth), CGFloat(config.windowHeight))
    }
    
    public func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        
        guard let id = Int(identifier), pages.indices.contains(id - 1) else {
            fatalError("Unexpected view controller identifier, \(identifier)")
        }
        return pages[id - 1]
    }
    
    public func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }
    
    public func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageControl.currentPage = pageController.selectedIndex
        pageController.completeTransition()
    }
}


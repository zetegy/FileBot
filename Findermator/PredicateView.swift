//
//  PredicateView.swift
//  Findermator
//
//  Created by Phil Zet on 10/14/21.
//

import Cocoa

class PredicateView: NSStackView, NibLoadable {
    
    public weak var customPredicateView: WrappedPredicateView?
    public weak var container: RuleView? {
        didSet {
            self.predicateButtonChanged(self)
        }
    }
    
    public var addOrdered: ((PredicateView) -> (Void))?
    public var removeOrdered: ((PredicateView) -> (Void))?
    
    public var predicate: RulePredicate {
        get {
            RulePredicate(predicateIndex: predicateButton.selectedTag(),
                          predicateTypeIndex: predicateTypeButton.selectedTag(),
                          predicateContents: customPredicateView?.value ?? [])
        }
        
        set {
            let predicate = newValue
            predicateButton.selectItem(withTag: predicate.predicateIndex)
            predicateButtonChanged(self)
            predicateTypeButton.selectItem(withTag: predicate.predicateTypeIndex)
            predicateTypeButtonChanged(self)
            customPredicateView?.value = predicate.predicateContents
        }
    }
    
    static private var customPredicateViewIndex = 3
    
    private lazy var trackingArea = TrackingArea(
        for: self,
        options: [
            .mouseEnteredAndExited,
            .activeInActiveApp
        ]
    )

    @IBOutlet weak var predicateButton: NSPopUpButton!
    @IBOutlet weak var predicateTypeButton: NSPopUpButton!
    @IBOutlet weak var removeConditionButton: NSButton!
    @IBOutlet weak var addConditionButton: NSButton!
    
    @IBOutlet weak var ifLabel: NSTextField!
    
    @IBAction func removeConditionClicked(_ sender: Any) {
        removeOrdered?(self)
    }
    
    @IBAction func addConditionClicked(_ sender: Any) {
        addOrdered?(self)
    }
    
    @IBAction func predicateButtonChanged(_ sender: Any) {
        predicateTypeButton.menu = NSMenu.create(fromEnum: PredicateType.self, includingItemWithRawValue: { rawValue in
            PredicateType(rawValue: rawValue)!.isIncluded(inPredicate: Predicate.allCases[predicateButton.selectedTag()])
        })
        
        updatePredicateView()
    }
    
    @IBAction func predicateTypeButtonChanged(_ sender: Any) {
        updatePredicateView()
    }
    
    private func updatePredicateView() {
        if let customPredicateView = customPredicateView {
            self.removeArrangedSubview(customPredicateView)
            customPredicateView.removeFromSuperview()
            self.customPredicateView = nil
        }
        
        let viewType = Predicate.allCases[predicateButton.selectedTag()].dataType.auxViewType
        
        let selectedComposition = predicateTypeButton.selectedTag() >= 0 ? predicateTypeButton.selectedTag() : 0
        let viewComposition = PredicateType.allCases[selectedComposition].composition
        
        if let container = container,
            let view = RuleView.auxView(for: viewType, composition: viewComposition, in: container) {
            
            self.insertArrangedSubview(view, at: PredicateView.customPredicateViewIndex)
            customPredicateView = view
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        predicateButton.menu = NSMenu.create(fromEnum: Predicate.self)
        
        predicateButtonChanged(self)
        
        self.removeConditionButton.isHidden = false
        self.removeConditionButton.alphaValue = 0
        self.addConditionButton.isHidden = false
        self.addConditionButton.alphaValue = 0
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingArea.update()
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        let shouldUpdate = removeConditionButton.isHidden
        
        self.removeConditionButton.alphaValue = 1
        self.addConditionButton.alphaValue = 1
        
        if shouldUpdate {
            updateTrackingAreas()
        }
        
    }
    
    override func layoutSubtreeIfNeeded() {
        super.layoutSubtreeIfNeeded()
        
        updateTrackingAreas()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.removeConditionButton.animator().alphaValue = 0
            self.addConditionButton.animator().alphaValue = 0
        } completionHandler: {
        }
    }
    
}

//
//  AppDelegate.swift
//  Findermator
//
//  Created by Phil Zet on 10/8/21.
//

import Cocoa
import LaunchAtLogin

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @CodableUserDefault("MonitoredDirectories_v5", defaultValue: [])
    public var directories: [MonitoredDirectory]
    
    @Storage(key: "Onboarded", defaultValue: false)
    public var isOnboardingComplete: Bool
    
    @Storage(key: "BigRedButton", defaultValue: false)
    public var isForceDisabled: Bool
    
    public var ignoredURLs: Set<URL> = []
    
    private weak var onboardingViewController: PZOnboardingController?
    
    func processActivation(for directory: MonitoredDirectory) {
        guard directory.isActive, directory.when == .newOrExistingFiles else { return }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: directory.url, includingPropertiesForKeys: nil)
            
            let ignoredURLsCopy = ignoredURLs
            ignoredURLs.removeAll()
            stopMonitors()
            for fileURL in directoryContents {
                _processFile(at: fileURL, for: directory)
                ignoredURLs.insert(fileURL)
            }
            ignoredURLs = ignoredURLsCopy
            resetMonitors()
        } catch {
            print(error)
        }
    }
    
    private func process(fileSystemEvent e: FSEventsEvent) {
        print(e)
        
        guard !isForceDisabled else { return }
        
        if let flag = e.flag,
           let directory = self.directories.first(where: { $0.isActive && e.path.contains($0.url.path) }) {
            
            let fileURL = URL(fileURLWithPath: e.path)
            
            if flag.contains(.rootChanged) || (flag.contains(.itemIsDir) && e.path == directory.url.path) {
                directoryListVC?.reloadInformation(for: directory)
            }
            
            if flag.contains(.itemCreated)/* && !flag.contains(.itemXattrMod)*/ {
                _processFile(at: fileURL, for: directory)
                ignoredURLs.insert(fileURL)
            }
        }
        
    }
    
    private func _processFile(at fileURL: URL, for directory: MonitoredDirectory) {
        if ignoredURLs.contains(fileURL) {
            ignoredURLs.remove(fileURL)
            return
        }
        
        let subfolderLevel = directory.includesSubfolders
        var watchesSubdirs = false
        if subfolderLevel != .none {
            let containerURL = fileURL.hasDirectoryPath ? fileURL : fileURL.deletingLastPathComponent()
            let diff = containerURL.pathComponents.count - directory.url.pathComponents.count
            
            if diff <= subfolderLevel.allowedLevelDifference {
                watchesSubdirs = true
            }
        }
        
        if fileURL.hasDirectoryPath {
            if watchesSubdirs,
                let directoryContents = try? FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil) {
                
                for url in directoryContents {
                    _processFile(at: url, for: directory)
                    ignoredURLs.insert(url)
                }
            }
            return
        }
        
        let containerURL = fileURL.deletingLastPathComponent()
        if containerURL.hasDirectoryPath {
            if !watchesSubdirs && containerURL != directory.url {
                return
            }
        }
        
        for rule in directory.rules {
            
            var isPredicateSatisfied = true
            var satContents = [String]()
            
            for predicate in rule.predicates {
                
                let result = Predicate.allCases[predicate.predicateIndex]
                    .matches(file: fileURL,
                             with: PredicateType.allCases[predicate.predicateTypeIndex],
                             predicateContents: predicate.predicateContents)
                
                if !result.isMatched {
                    isPredicateSatisfied = false
                } else {
                    satContents.append(result.contents.first ?? "")
                }
                
            }
            
            if isPredicateSatisfied {
                // execute the action
                PredicateAction.allCases[rule.action.actionIndex].execute(forFile: fileURL, actionContents: rule.action.actionContents, satPredicateContents: satContents)
            }
        }
    }
    
    var directoryListVC: DirectoryListViewController? {
        NSApp.windows.first(where: { $0.contentViewController is DirectoryListViewController })?.contentViewController as? DirectoryListViewController
    }
    
    func stopMonitors() {
        FSEvents.stopWatching(for: ObjectIdentifier(self))
    }
    
    func resetMonitors() {
        guard !isForceDisabled else { return }
        
        stopMonitors()
        
        try? FSEvents.startWatching(paths: directories.map { $0.url.path },
                                    for: ObjectIdentifier(self),
                                    with: { [weak self] e in
            self?.process(fileSystemEvent: e)
        })
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        SecurityBookmarks.shared.loadBookmarks()
        resetMonitors()
        
        if !isOnboardingComplete {
            showOnboarding()
        }
        
    }
    
    func showOnboarding() {
        
        LaunchAtLogin.isEnabled = true
        
        let config = OnboardingConfig(
            windowWidth: 500,
            windowHeight: 600,
            windowTitle: "",
            pageControlWidth: 200,
            pageControlHeight: 20,
            pageControlVerticalDistanceFromBottom: 20,
            pageTransitionStyle: .horizontalStrip
        )
        
        let vc = PZOnboardingController(with: config)
        
        let onboardingViewControllers = [
            OnboardingPageViewController.createFromNib()!
                .configured(withTitle: "Welcome to FileBot.",
                            descriptionString: "Create dynamic automations for your folders. They will be activated whenever you add a new file. Easily build useful workflows to organize your folders, sort documents, cleanup old data, and more.",
                            image: NSImage(named: "Icon"),
                            customViews: [
                                vc.spacer,
                                launchAtLoginButton,
                                vc.spacer,
                                vc.nextItemButton
                            ]),
            OnboardingPageViewController.createFromNib()!
                .configured(withTitle: "Easy Automations.",
                            descriptionString: "Your automations are always accessible from the Menu Bar. Activate one of the existing automations, such as sorting the Downloads folder by document type. Enable, disable, and customize your automations – all from the Menu Bar.",
                            image: NSImage(named: "Onboard2"),
                            customViews: [
                                vc.spacer,
                                vc.nextItemButton
                            ]),
            OnboardingPageViewController.createFromNib()!
                .configured(withTitle: "Create Your Own.",
                            descriptionString: "Easily create your own automations right from the Menu Bar. Build your workflows in an intuitive visual manner, or use more advanced features, such as variables and modifiers. You can always learn more about the features available by clicking the help button.",
                            image: NSImage(named: "Onboard3"),
                            customViews: [
                                vc.spacer,
                                vc.doneButton
                            ]),
        ]

        vc.setUp(for: onboardingViewControllers)
        
        vc.runWindow()
        
        onboardingViewController = vc
        
        #if !DEBUG
        isOnboardingComplete = true
        #endif
    }
    
    lazy var launchAtLoginButton: NSButton = {
        let button = NSButton(title: "Launch at Login", target: self, action: #selector(launchAtLoginButtonClicked))
        button.setButtonType(.switch)
        button.state = LaunchAtLogin.isEnabled ? .on : .off
        return button
    }()
    
    @objc private func launchAtLoginButtonClicked() {
        LaunchAtLogin.isEnabled = launchAtLoginButton.state == .on
        print(LaunchAtLogin.isEnabled)
    }
    
    func application(_ sender: NSApplication,
                     openFile filename: String) -> Bool {
        FileExporter().importFile(at: URL(fileURLWithPath: filename))
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    deinit {
        FSEvents.stopWatching(for: ObjectIdentifier(self))
    }

}

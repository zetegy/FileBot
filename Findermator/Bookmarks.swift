//
//  Bookmarks.swift
//  GetFolderAccessMacOS
//
//  Created by Phil Zet on 21/12/17.
//  Copyright © 2017 Phil Zet. All rights reserved.
//

import Foundation
import Cocoa

class SecurityBookmarks {
    
    static var shared = SecurityBookmarks()
    
    var bookmarks = [URL: Data]()
    
    func openFolderSelection(from window: NSWindow, _ completion: @escaping ((URL?) -> Void)) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.beginSheetModal(for: window) { [unowned self] result in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    self.storeFolderInBookmark(url: url)
                    completion(url)
                }
            }
        }
    }
    
    func saveBookmarksData()
    {
        let path = getBookmarkPath()
//        NSKeyedArchiver.archiveRootObject(bookmarks, toFile: path)
        if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: bookmarks, requiringSecureCoding: true) {
            try? dataToBeArchived.write(to: URL(fileURLWithPath: path))
        }
    }
    
    func storeFolderInBookmark(url: URL)
    {
        do
        {
            let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            bookmarks[url] = data
        }
        catch
        {
            Swift.print ("Error storing bookmarks")
        }
        
    }
    
    func getBookmarkPath() -> String
    {
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        url = url.appendingPathComponent("Bookmarks.dict")
        return url.path
    }
    
    func loadBookmarks()
    {
        let path = getBookmarkPath()
//        bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! [URL: Data]
        
        if let archivedData = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let bookmarks = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedData)) as? [URL: Data] {
            self.bookmarks = bookmarks
            for bookmark in bookmarks
            {
                restoreBookmark(bookmark)
            }
        }
    }
    
    
    
    func restoreBookmark(_ bookmark: (key: URL, value: Data))
    {
        let restoredUrl: URL?
        var isStale = false
        
        Swift.print ("Restoring \(bookmark.key)")
        do
        {
            restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        }
        catch
        {
            Swift.print ("Error restoring bookmarks")
            restoredUrl = nil
        }
        
        if let url = restoredUrl
        {
            if isStale
            {
                Swift.print ("URL is stale")
            }
            else
            {
                if !url.startAccessingSecurityScopedResource()
                {
                    Swift.print ("Couldn't access: \(url.path)")
                }
            }
        }
        
    }
    
    
}

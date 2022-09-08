//
//  AppDelegate.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//

import SwiftUI
import CoreData
import HotKey


class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var popover = NSPopover()
    var menu = NSMenu()
    var statusBar: StatusBarController?
    var timer: Timer!
    let pasteboard: NSPasteboard = .general
    var lastChangeCount: Int = 0
    var clips = Clips()
    var hotKeys = [HotKey(key: .h, modifiers: [.control, .command]), HotKey(key: .j, modifiers: [.control, .command]), HotKey(key: .k, modifiers: [.control, .command]), HotKey(key: .l, modifiers: [.control, .command]), HotKey(key: .semicolon, modifiers: [.control, .command])]
    var keys = ["h","j","k","l",";"]
    var internallyChanged = false
    
    
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        Self.popover.contentViewController = NSHostingController(rootView: PopoverView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext).environmentObject(clips))
        Self.popover.behavior = .transient
        
        statusBar = StatusBarController(Self.popover)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = self.menu
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "paperclip")
        }
        self.setupMenu()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (t) in
            self.readClipboard()
            self.hotkeyMappers()
        }
    }
    
    @objc func didTap(_ sender: NSMenuItem) {
        self.hotKeyCommand(i: sender.tag)
    }
    
    func setupMenu() {
        for i in 0 ..< self.clips.clips.count {
            let menuItem = NSMenuItem(title: limitStringLength(self.clips.clips[i]), action: #selector(didTap), keyEquivalent: self.keys[i])
            menuItem.tag = i
            menuItem.keyEquivalentModifierMask = [.control, .command];
            if self.clips.clips[i].isEmpty {
                menuItem.isHidden = true
            }
            else {
                menuItem.isHidden = false
            }
            self.menu.addItem(menuItem)
        }

        self.menu.addItem(NSMenuItem.separator())

        self.menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    func refreshMenu(){
        for i in 0 ..< self.clips.clips.count {
            self.menu.item(at: i)?.title = limitStringLength(self.clips.clips[i])
            if self.clips.clips[i].isEmpty {
                self.menu.item(at: i)?.isHidden = true
            }
            else {
                self.menu.item(at: i)?.isHidden = false
            }
        }
    }
    
    func limitStringLength(_ val: String) -> String{
        let trimmed = val.components(separatedBy: .newlines).joined()
        if trimmed.count < 60 {
            return trimmed
        }
        return trimmed.prefix(57) + "..."
    }

    
    // MARK: - Core Data stack
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ClipperTool")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
        timer.invalidate()
    }
    
    var context: NSManagedObjectContext {
        return Self.persistentContainer.viewContext
    }
    
    func readClipboard(){
        if self.lastChangeCount != self.pasteboard.changeCount {
            self.lastChangeCount = self.pasteboard.changeCount
            if self.internallyChanged {
                self.internallyChanged = false
            }
            else {
                guard let items = self.pasteboard.pasteboardItems else {return}
                guard let item = items.first else {return}
                let pastedType = item.availableType(from: [.fileURL, .string, .URL, .multipleTextSelection, .pdf, .png])
                print(item.types)
                //print(pastedType)
                self.saveClip(pasted: item)
            }
        }
    }
    
    func saveClip(pasted: NSPasteboardItem) {
        self.clips.append(pasted: pasted)
        self.refreshMenu()
    }
    
    func hotkeyMappers() {
        for i in 0...4 {
            self.hotKeys[i].keyDownHandler = {
                if self.clips.clips.count >= i + 1 {
                    print("\(self.clips.clips[i])\n")
                    self.hotKeyCommand(i: i)
                }
                else {
                    print("Nothing to paste.")
                }
            }
        }
        return
    }
    
    func hotKeyCommand(i: Int) {
        let _ = self.setTempClipboard(i:i)
        Task {
            await self.simulatePaste()
        }
        //self.resetClipboardToOriginal(tempClipString: tempString)
    }
    
    func setTempClipboard(i: Int) -> String {
        self.internallyChanged = true
        var tempClip: NSPasteboardItem
        tempClip = (self.pasteboard.pasteboardItems?.first)!
        let tempClipString = tempClip.string(forType: .string)!
        self.pasteboard.clearContents()
        self.pasteboard.setString(self.clips.clips[i], forType: .string)
        return tempClipString
    }
    
    func simulatePaste() async -> String {
        let src = CGEventSource(stateID: .privateState)

        let cmdd = CGEvent(keyboardEventSource: src, virtualKey: 0x38, keyDown: true)
        let cmdu = CGEvent(keyboardEventSource: src, virtualKey: 0x38, keyDown: false)
        let vd = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let vu = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)

        vd?.flags = CGEventFlags.maskCommand;

        let loc = CGEventTapLocation.cghidEventTap
    
        cmdd?.post(tap: loc)
        vd?.post(tap: loc)
        vu?.post(tap: loc)
        cmdu?.post(tap: loc)
        
        return "Completed paste."
    }
    
    func resetClipboardToOriginal(tempClipString: String) {
        self.internallyChanged = true
        self.pasteboard.clearContents()
        self.pasteboard.setString(tempClipString, forType: .string)
    }
}

class Clips: ObservableObject {
    @Published var clips = ["","","","",""]
    
    func append(pasted: NSPasteboardItem){
        let newPastedData = pasted.string(forType: .string)!
        if self.clips.count == 5 {
            self.clips.removeLast()
        }
        self.clips.insert(newPastedData, at: 0)
    }
}

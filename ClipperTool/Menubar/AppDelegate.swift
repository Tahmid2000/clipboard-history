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
    var menu = NSMenu()
    var timer: Timer!
    let pasteboard: NSPasteboard = .general
    var lastChangeCount: Int = 0
    var clips = Clips()
    var hotKeys = [HotKey(key: .h, modifiers: [.control, .command]), HotKey(key: .j, modifiers: [.control, .command]), HotKey(key: .k, modifiers: [.control, .command]), HotKey(key: .l, modifiers: [.control, .command]), HotKey(key: .semicolon, modifiers: [.control, .command])]
    var keys = ["h","j","k","l",";"]
    var internallyChanged = false
    
    
    //private var window: NSWindow!
    private var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.close()
        }
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
        self.hotKeyCommandData(i: sender.tag)
    }
    
    private func newWindowInternal() -> NSWindow {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 680, height: 600),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(true)
            NSApp.activate(ignoringOtherApps: true)
            window.positionCenter()
            return window
        }
    
    @objc func openAbout() {
//        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
//        NSApp.activate(ignoringOtherApps: true)
        self.newWindowInternal().contentView = NSHostingView(rootView: ContentView().fixedSize())
    }
    
    func setupMenu() {

        for i in 0 ..< self.clips.clips.count {
            let menuItem = NSMenuItem(title: limitStringLength(self.clips.clipDescriptions[i]), action: #selector(didTap), keyEquivalent: self.keys[i])
            menuItem.tag = i
            menuItem.keyEquivalentModifierMask = [.control, .command];
            if self.clips.clipFirstTime[i] {
                menuItem.isHidden = true
            }
            else {
                menuItem.isHidden = false
            }
            self.menu.addItem(menuItem)
        }

        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: ""))
        self.menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func refreshMenu(){
        for i in 0 ..< self.clips.clips.count {
            self.menu.item(at: i)?.title = limitStringLength(self.clips.clipDescriptions[i])
            if self.clips.clipFirstTime[i] {
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

    
    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
        timer.invalidate()
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
                let itemDescription = item.string(forType: .string) ?? "(No Description Available)"
                var pasteType = item.types.first!
                if item.types.contains(NSPasteboard.PasteboardType(rawValue: "public.jpeg")) {
                    pasteType = NSPasteboard.PasteboardType(rawValue: "public.jpeg")
                }
                self.saveClipAsData(pasteData: self.pasteboard.data(forType: item.types.first!)!, pasteType: pasteType, pasteDescription: itemDescription)
                //self.saveClip(pasted: item)
            }
        }
    }
    
    func saveClipAsData(pasteData: Data, pasteType: NSPasteboard.PasteboardType, pasteDescription: String){
        self.clips.appendData(pasteData: pasteData, pasteType: pasteType, pasteDescription: pasteDescription)
        self.refreshMenu()
    }
    
    
//    func saveClip(pasted: NSPasteboardItem) {
//        self.clips.append(pasted: pasted)
//        self.refreshMenu()
//    }
    
    func hotkeyMappers() {
        for i in 0...4 {
            self.hotKeys[i].keyDownHandler = {
                if self.clips.clips.count >= i + 1 {
//                    print("\(self.clips.clips[i])\n")
//                    self.hotKeyCommand(i: i)
                    self.hotKeyCommandData(i: i)
                }
                else {
                    print("Nothing to paste.")
                }
            }
        }
        return
    }
    
    func hotKeyCommandData(i: Int){
        let _ = self.setDataToClipboard(i: i)
        Task {
            await self.simulatePaste()
        }
    }
    
//    func hotKeyCommand(i: Int) {
//        let _ = self.setTempClipboard(i:i)
//        Task {
//            await self.simulatePaste()
//        }
//        self.resetClipboardToOriginal(tempClipString: tempString)
//    }
    
    func setDataToClipboard(i: Int) {
        print(self.clips.clips)
        print(self.clips.clipTypes)
        self.internallyChanged = true
        self.pasteboard.clearContents()
        self.pasteboard.setData(self.clips.clips[i], forType: self.clips.clipTypes[i])
    }
    
    
//    func setTempClipboard(i: Int) -> String {
//        self.internallyChanged = true
//        var tempClip: NSPasteboardItem
//        tempClip = (self.pasteboard.pasteboardItems?.first)!
//        let tempClipString = tempClip.string(forType: .string)!
//        self.pasteboard.clearContents()
//        self.pasteboard.setString(self.clips.clips[i], forType: .string)
//        return tempClipString
//    }
    
    func simulatePaste() async {
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
    }
    
    func resetClipboardToOriginal(tempClipString: String) {
        self.internallyChanged = true
        self.pasteboard.clearContents()
        self.pasteboard.setString(tempClipString, forType: .string)
    }
}

class Clips: ObservableObject {
    //@Published var clips = ["","","","",""]
    @Published var clips = [Data(), Data(), Data(), Data(), Data()]
    @Published var clipTypes = [NSPasteboard.PasteboardType.string,NSPasteboard.PasteboardType.string,NSPasteboard.PasteboardType.string,NSPasteboard.PasteboardType.string,NSPasteboard.PasteboardType.string]
    @Published var clipDescriptions = ["", "", "", "", ""]
    @Published var clipFirstTime = [true,true,true,true,true]
//    func append(pasted: NSPasteboardItem){
//        guard let newPastedData = pasted.string(forType: .string) else {return}
//        if newPastedData.isEmpty {
//            return
//        }
//        if self.clips.count == 5 {
//            self.clips.removeLast()
//        }
//        self.clips.insert(newPastedData, at: 0)
//    }
    
    func appendData(pasteData: Data, pasteType: NSPasteboard.PasteboardType, pasteDescription: String){
        if self.clips.count == 5  {
            self.clips.removeLast()
            self.clipTypes.removeLast()
            self.clipDescriptions.removeLast()
            self.clipFirstTime.removeLast()
        }
        self.clips.insert(pasteData, at: 0)
        self.clipTypes.insert(pasteType, at: 0)
        self.clipDescriptions.insert(pasteDescription, at: 0)
        self.clipFirstTime.insert(false, at: 0)
    }
}


extension NSWindow {
    
    /// Positions the `NSWindow` at the horizontal-vertical center of the `visibleFrame` (takes Status Bar and Dock sizes into account)
    public func positionCenter() {
        if let screenSize = screen?.visibleFrame.size {
            self.setFrameOrigin(NSPoint(x: (screenSize.width-frame.size.width)/2, y: (screenSize.height-frame.size.height)/2))
        }
    }
    /// Centers the window within the `visibleFrame`, and sizes it with the width-by-height dimensions provided.
    public func setCenterFrame(width: Int, height: Int) {
        if let screenSize = screen?.visibleFrame.size {
            let x = (screenSize.width-frame.size.width)/2
            let y = (screenSize.height-frame.size.height)/2
            self.setFrame(NSRect(x: x, y: y, width: CGFloat(width), height: CGFloat(height)), display: true)
        }
    }
    /// Returns the center x-point of the `screen.visibleFrame` (the frame between the Status Bar and Dock).
    /// Falls back on `screen.frame` when `.visibleFrame` is unavailable (includes Status Bar and Dock).
    public func xCenter() -> CGFloat {
        if let screenSize = screen?.visibleFrame.size { return (screenSize.width-frame.size.width)/2 }
        if let screenSize = screen?.frame.size { return (screenSize.width-frame.size.width)/2 }
        return CGFloat(0)
    }
    /// Returns the center y-point of the `screen.visibleFrame` (the frame between the Status Bar and Dock).
    /// Falls back on `screen.frame` when `.visibleFrame` is unavailable (includes Status Bar and Dock).
    public func yCenter() -> CGFloat {
        if let screenSize = screen?.visibleFrame.size { return (screenSize.height-frame.size.height)/2 }
        if let screenSize = screen?.frame.size { return (screenSize.height-frame.size.height)/2 }
        return CGFloat(0)
    }

}

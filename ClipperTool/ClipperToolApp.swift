//
//  ClipperToolApp.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//

import SwiftUI

@main
struct ClipperToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}



//
//  ContentView.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//

import SwiftUI
import CoreData

struct ContentView: View {

    var body: some View {
        Group {
            Text("Welcome to Clipper!")
                .bold()
            Spacer()
            Text("Version 1.0")
            Text("Designed by: [Tahmid Imran](https://www.tahmidimran.com)")
            Spacer()
            Text("Copyright © 2022 Tahmid Imran")
                .bold()
        }
        .padding(30)
        .padding([.bottom], 15)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification), perform: { _ in
            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
            NSApp.mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        })
    }
}

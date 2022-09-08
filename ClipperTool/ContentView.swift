//
//  ContentView.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        Text("Welcome to Clipper!")
            .padding(64)
    }
}

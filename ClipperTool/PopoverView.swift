//
//  PopoverView.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//

import SwiftUI



struct PopoverView: View {
    @Environment(\.managedObjectContext) var viewContext
    
//    @FetchRequest var clips: FetchedResults<Clip>
    @EnvironmentObject var clips: Clips
    
//    init() {
//        let request: NSFetchRequest<Clip> = Clip.fetchRequest()
//        request.fetchLimit = 5
//        request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.timeCopied, ascending: false)]
//        _clips = FetchRequest(fetchRequest: request)
//    }
    
    var body: some View {
        ClipList(clips: clips)
    }
}

struct ClipList: View {

    var clips: Clips
    var keyboardIds = [KeyEquivalent("j"),KeyEquivalent("k"),KeyEquivalent("l"),KeyEquivalent(";"),KeyEquivalent("'")]
    var keys = ["h","j","k","l",";"]
    
    var body: some View {
        
        VStack(alignment: .leading){
            ForEach(0 ..< self.clips.clips.count) {
                if !self.clips.clips[$0].isEmpty {
                    ClipRow(clip: limitStringLength(self.clips.clips[$0]), keyId: self.keys[$0])
                }
            }
            
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
        
    }
    
    func limitStringLength(_ val: String) -> String{
        let trimmed = val.components(separatedBy: .newlines).joined()
        if trimmed.count < 60 {
            return trimmed
        }
        return trimmed.prefix(57) + "..."
    }
    
}

struct ClipRow: View {
    var clip: String
    var keyId: String
    
    var body: some View {
        HStack {
            Text(clip)
            Spacer()
            Text("⌘⌃\(keyId)")
        }
    }
}

struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverView()
    }
}


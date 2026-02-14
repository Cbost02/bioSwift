//
//  ContentView.swift
//  bio_app_test
//
//  Created by Cromwell on 1/23/26.
// Committing to GitHub...

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// model for single tap
struct TouchEvent: Codable // Means it can be exported into something clean!
{
    let time: Double
    let x: Double
    let y: Double
    let phase: String
}

// export format
struct TapSessionExport: Codable
{
    let startedAt: Date
    let tapCount: Int
    let taps: [TouchEvent]
}

struct ContentView: View
{
    // Storage needed for tap count, if the session is running, or tap model
    @State private var tapCount: Int = 0
    @State private var touchEvents: [TouchEvent] = []
    @State private var isRunning = false
    
    // For file output
    @State private var lastExportURL: URL? = nil
    @State private var exportStatus: String = ""
    
    // Keeps the time of the first tap
     @State private var startTime = Date()
    
    @State private var sessionTouchStartTimestamp: TimeInterval? = nil
    
    
    var body: some View
    {
        VStack
        {
            Text("Tap count: \(tapCount)").font(.headline)
            
            // If the session is running, display Reset, otherwise display Start
            Button(isRunning ? "Reset Session" : "Start Session")
            {
                isRunning = true
                startTime = Date()
                tapCount = 0
                touchEvents.removeAll()
                sessionTouchStartTimestamp = nil // set to nil because new sessions
                
                
                
            }.buttonStyle(.borderedProminent)
            
            
          
            Button("Stop") // Stops the session
            {
                isRunning = false
            }.disabled(!isRunning)
            
            Button("Export Session") // Exports data from the session
            {
                exportSession()
            }.disabled(touchEvents.isEmpty)
            
            Text(exportStatus).font(.footnote).foregroundStyle(.secondary)
            
            if let url = lastExportURL
            {
                ShareLink(item: url)
                {
                    Text("Share Export File")
                }
            }
            
            // Custom SwiftUI view built from UIKit
            TouchPadView
            { // The code inside here is not UI code || It is a touch event handler!
                phase, point, timestamp in
                
                guard isRunning else{ return }
                
                if sessionTouchStartTimestamp == nil
                {
                    sessionTouchStartTimestamp = timestamp
                }
                
                let elsapsed = timestamp - (sessionTouchStartTimestamp ?? timestamp)
                
                touchEvents.append(TouchEvent(time: elsapsed, x: point.x, y: point.y, phase: phase))
                
                if phase == "ended"
                {
                    tapCount += 1
                }
                
                
            }.frame(height: 300).padding(.horizontal)
            
            
            
            // Displays the tap # and the time it occured
            List(touchEvents.indices, id: \.self)
            {
                i in
                Text("Tap: \(i+1): " + String(format: "%.3f", touchEvents[i].time) + "s")
            }
            
        }
        
    }
    
    func exportSession()
    {
        // insert the current session into the exportable format
        let session = TapSessionExport(startedAt: startTime, tapCount: tapCount, taps: touchEvents)
        
        
        do
        {
            // Creates a tool that turns data into JSON text
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            
            // session object ---> bytes (raw file data)
            let data = try encoder.encode(session) // 'try' is needed since encoding could fail
            
            
            // Finds a safe space to save the file || Saves in app's documents folder
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            
            // Creates file name
            let filename = "tap_session_" + ISO8601DateFormatter().string(from: Date()) + ".json"
            
            // creates full file location || "Save this file here, with this name"
            let url = docs.appendingPathComponent(filename)
            
            
            // Write the file to the disk || '.atomic' writes a temp file before writing the actual one; prvents corrupted files
            try data.write(to: url, options: [.atomic])
            
            // Save the location of the last exported file || updates export status
            lastExportURL = url
            exportStatus = "Exported: \(filename)"
        }
        catch
        {
            exportStatus = "Export failed: \(error.localizedDescription)"
        }
    }
}

#Preview
{
    ContentView()
}

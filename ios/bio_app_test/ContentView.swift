//
//  ContentView.swift
//  bio_app_test
//
//  Created by Cromwell on 1/23/26.
//

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

// export the data from the session
struct TraceSessionExport: Codable
{
    let startedAt: Date
    let strokeCount: Int
    let samples: [TouchEvent]
}


struct ContentView: View
{
    // Storage needed for tap count, if the session is running, or tap model
    @State private var strokeCount: Int = 0
    @State private var touchEvents: [TouchEvent] = []
    @State private var isRunning = false
    
    // For file output
    @State private var lastExportURL: URL? = nil
    @State private var exportStatus: String = ""
    
    // Keeps the time of the first tap
    @State private var startTime = Date()
    @State private var sessionTouchStartTimestamp: TimeInterval? = nil
    
    
    @State private var touchPadSize: CGSize = .zero
    
    var body: some View
    {
        VStack
        {
            Text("Strokes completed: \(strokeCount)").font(.headline)
            
            
            // If the session is running, display Reset, otherwise display Start
            Button(isRunning ? "Reset Session" : "Start Session")
            {
                isRunning = true
                startTime = Date()
                strokeCount = 0
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
            // This represents the Zig-Zag tracing pad
            ZStack
            {
                ZigZagOverlay().allowsHitTesting(false)       // draws the path + dots
                
                TouchPadView
                { // The code inside here is not UI code || It is a touch event handler!
                    phase, point, timestamp in
                    
                    guard isRunning else{ return }
                    guard phase == "began" || phase == "moved" || phase == "ended" else {return}
                    guard touchPadSize.width > 0, touchPadSize.height > 0 else {return}
                    
                    if sessionTouchStartTimestamp == nil
                    {
                        sessionTouchStartTimestamp = timestamp
                    }
                    
                    let elapsed = timestamp - (sessionTouchStartTimestamp ?? timestamp)
                    
                    
                    let nx = max(0.0, min(1.0, point.x / touchPadSize.width))
                    let ny = max(0.0, min(1.0, point.y / touchPadSize.height))
                    
                    touchEvents.append(TouchEvent(time: elapsed, x: nx, y: ny, phase: phase))
                    
                    if phase == "ended"
                    {
                        strokeCount += 1
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.35), lineWidth: 1))
            .shadow(radius: 2).background(GeometryReader
                                         {
                                             geo in
                                             Color.clear
                                                 .onAppear {touchPadSize = geo.size}
                                                 .onChange(of: geo.size)
                                             {
                                                 _, newSize in touchPadSize = newSize
                                             }
                                         })
            
            
            
            // Displays the tap # and the time it occured
            List(touchEvents.indices, id: \.self)
            {
                i in
                Text("Sample \(i+1): t=\(String(format: "%.3f", touchEvents[i].time))s (\(String(format: "%.3f", touchEvents[i].x)), \(String(format: "%.3f", touchEvents[i].y)) \(touchEvents[i].phase)")
                    .font(.caption)
                    .lineLimit(1)
            }
            
        }
        
    }
    
    func exportSession()
    {
        // insert the current session into the exportable format
        let session = TraceSessionExport(
            startedAt: startTime,
            strokeCount: strokeCount,
            samples: touchEvents
        )
        
        
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
            let filename = "zigzag_session_" + ISO8601DateFormatter().string(from: Date()) + ".json"
            
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

//
//  HomeView.swift
//  tap_count_test
//
//  Created by Cromwell on 2/20/26.
//

import SwiftUI

struct HomeView: View
{
    
    @State private var animateGradient: Bool = false
        
    private let startColor: Color = .blue
    private let endColor: Color = .green
        
    var body: some View
    {
        
       
        NavigationStack
        {
            ZStack
            {
                LinearGradient(
                    colors: [startColor, endColor],
                    startPoint: animateGradient ? .bottomTrailing : .topLeading,
                    endPoint: animateGradient ? .topLeading : .bottomTrailing
                )
                .ignoresSafeArea()
                .hueRotation(.degrees(animateGradient ? 35 : 0))
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
                VStack(alignment: .leading, spacing: 18)
                {
                    VStack(alignment: .leading, spacing: 6)
                    {
                        Text("Signals to Pathways")
                            .font(.largeTitle.bold())
                            .italic()
                            

                        Text("Short motor-control activities that record human-motor signals (touch timing and movement). Exports anonymized JSON for analysis.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12)
                    {
                        NavigationLink
                        {
                            ContentView() // your Zig-Zag activity screen
                        }
                        label:
                        {
                            ActivityCard(
                                title: "Zig-Zag Tracing",
                                subtitle: "Trace a path smoothly and accurately",
                                tag: "Ready"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink
                        {
                            TappingView()
                        }
                        label:
                        {
                            ActivityCard(
                                title: "Tapping",
                                subtitle: "Target taps & consistency",
                                tag: "Ready")
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink
                        {
                            SwipingView()
                        }
                        label:
                        {
                            ActivityCard(
                                title: "Swiping",
                                subtitle: "Swipe speed & control",
                                tag: "Ready")
                        }
                        .buttonStyle(.plain)
                        
                        
                        NavigationLink
                        {
                            OrientationView()
                        }
                        label:
                        {
                            ActivityCard(
                                title: "Orientation",
                                subtitle: "Device motion stability",
                                tag: "Ready")
                        }.buttonStyle(.plain)
        

                    }

                    Spacer()

                    Text("Data & Privacy: No name required. Sessions are exportable as JSON from each activity screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .background(RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                )
                .padding()
            }
           
        }
                
    }
}

private struct ActivityCard: View
{
    let title: String
    let subtitle: String
    let tag: String

    var body: some View
    {
        HStack(alignment: .top, spacing: 12)
        {
            VStack(alignment: .leading, spacing: 4)
            {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(tag)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tagBackground)
                .foregroundStyle(tagForeground)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var tagBackground: Color
    {
        tag == "Ready" ? Color.green.opacity(0.15) : Color.gray.opacity(0.15)
    }

    private var tagForeground: Color
    {
        tag == "Ready" ? Color.green : Color.gray
    }
}

#Preview
{
    HomeView()
}

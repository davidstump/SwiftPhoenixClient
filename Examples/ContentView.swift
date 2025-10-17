//
//  ContentView.swift
//  Examples
//
//  Created by Daniel Rees on 8/23/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: 1) {
                    row(
                        title: "WebSocket Echo",
                        subtitle: "Test the underlying websocket using a basic Echo server."
                    )
                }
                
                NavigationLink(value: 2) {
                    row(
                        title: "Local Phoenix Server",
                        subtitle: "Test phoenix functionality and reconnections"
                    )
                }
                
                NavigationLink(value: 3) {
                    row(
                        title: "DYWL Chat Example",
                        subtitle: "A chat example using the github.com/dwyl/phoenix-chat-example project"
                    )
                }
            }
            .navigationTitle("Select Test")
            .navigationDestination(for: Int.self) { id in
                switch id {
                case 1:
                    EchoExample()
                case 2:
                    LocalExample()
                case 3:
                    DetailView(title: "DYWL Chat Example")
                default:
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func row(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct DetailView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentViewView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

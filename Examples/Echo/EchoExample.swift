//
//  EchoExample.swift
//  Examples
//
//  Created by Daniel Rees on 8/23/25.
//  Copyright © 2025 SwiftPhoenixClient. All rights reserved.
//

import SwiftUI
import SwiftPhoenixClient

struct EchoExample: View {
    
    @StateObject private var vm = EchoViewModel()
    @State private var bottomID = "BOTTOM"
    
    var body: some View {
        
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.messages) { msg in
                        HStack {
                            if msg.isMe { Spacer(minLength: 40) }
                            Text(msg.text)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(msg.isMe ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            if !msg.isMe { Spacer(minLength: 40) }
                        }
                        .padding(.horizontal)
                    }
                    // Scroll target
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages) { _, _ in
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
        .navigationTitle("Echo Example")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(vm.isConnected ? "Disconnect" : "Connect") {
                    Task {
                        await vm.toggleConnection()
                    }
                }
            }
        }
        // Input bar fixed to bottom, safe with keyboard
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                TextField("Message…", text: $vm.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(!vm.isConnected && vm.draft.isEmpty == false) // optional: allow typing anytime
                    .onSubmit(vm.send)
                
                Button("Send") { vm.send() }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
    }
    
}

#Preview {
    EchoExample()
}

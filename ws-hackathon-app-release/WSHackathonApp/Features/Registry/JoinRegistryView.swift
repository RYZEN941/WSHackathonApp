//
//  JoinRegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct JoinRegistryView: View {
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var roomCode = ""
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Join a Registry")
                .font(WSFont.heading(32))
                .foregroundStyle(Color.wsNavy)
                .padding(.top, 40)
            
            Text("Enter the 8-character room code to join an existing registry and start collaborating.")
                .font(WSFont.body(16))
                .foregroundStyle(Color.wsTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("ROOM CODE")
                    .font(WSFont.label(12))
                    .tracking(1)
                    .foregroundStyle(Color.wsNavy)
                
                TextField("e.g. 8A7B6C5D", text: $roomCode)
                    .font(WSFont.body(18))
                    .padding()
                    .background(Color.wsSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(errorMessage != nil ? Color.wsAccent : Color.wsBorder, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                
                if let error = errorMessage {
                    Text(error)
                        .font(WSFont.caption(12))
                        .foregroundStyle(Color.wsAccent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            WSPrimaryButton(title: "Join Room") {
                joinRoom()
            }
            .disabled(roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .wsAppBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func joinRoom() {
        withAnimation {
            let success = registryRepo.joinRegistry(by: roomCode)
            if success {
                errorMessage = nil
                if !tabBarVM.registryPath.isEmpty {
                    tabBarVM.registryPath.removeLast()
                }
            } else {
                errorMessage = "Invalid room code. Please try again."
            }
        }
    }
}

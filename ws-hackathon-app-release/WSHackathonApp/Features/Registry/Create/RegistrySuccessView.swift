//
//  RegistrySuccessView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistrySuccessView: View {

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wsSurface)
                    .frame(width: 140, height: 140)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(Color.wsAccent)
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.bottom, 32)

            VStack(spacing: 10) {
                Text("Registry Created")
                    .font(WSFont.display(30))
                    .foregroundStyle(Color.wsNavy)

                if let name = registryRepo.currentRegistry?.displayName {
                    Text(name)
                        .font(WSFont.body(16))
                        .foregroundStyle(Color.wsTextSecondary)
                    
                    VStack(spacing: 4) {
                        Text("ROOM CODE")
                            .font(WSFont.label(10))
                            .tracking(2)
                            .foregroundStyle(Color.wsMuted)
                        Text(registryRepo.shareCode)
                            .font(WSFont.heading(24))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.wsNavy)
                            .tracking(2)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color.wsSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.wsBorder, lineWidth: 1))
                    .padding(.top, 16)
                }

                Text("Start adding gifts your guests will love.")
                    .font(WSFont.body(14))
                    .foregroundStyle(Color.wsMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }

            Spacer()

            WSPrimaryButton(title: "Start Browsing", icon: "house.fill") {
                tabBarVM.resetRegistryFlow()
                tabBarVM.selectTab(.home)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .wsAppBackground()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

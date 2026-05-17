//
//  CollaborationFacepileView.swift
//  WSHackathonApp
//
//  Created by Antigravity on 05/17/26.
//

import SwiftUI

struct FacepileUser: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let color: Color
}

struct CollaborationFacepileView: View {
    // 5 active mock users currently collaborating
    let users: [FacepileUser] = [
        FacepileUser(name: "Alex Miller", initials: "AM", color: Color(red: 0.76, green: 0.60, blue: 0.42)), // Warm Gold
        FacepileUser(name: "Taylor Swift", initials: "TS", color: Color(red: 0.08, green: 0.18, blue: 0.36)), // Navy
        FacepileUser(name: "Jordan Smith", initials: "JS", color: Color(red: 0.18, green: 0.36, blue: 0.27)), // Hunter Green
        FacepileUser(name: "Morgan Jones", initials: "MJ", color: Color(red: 0.48, green: 0.12, blue: 0.24)), // Wine Red
        FacepileUser(name: "Casey Davis", initials: "CD", color: Color(red: 0.36, green: 0.24, blue: 0.48))  // Deep Purple
    ]
    
    var body: some View {
        HStack(spacing: -10) {
            if users.count <= 3 {
                ForEach(users) { user in
                    avatarCircle(for: user)
                }
            } else {
                // Show first 2 users
                ForEach(users.prefix(2)) { user in
                    avatarCircle(for: user)
                }
                
                // Show "+ rest" badge (Rule: shows 2 and + rest of them if > 3 people)
                Text("+\(users.count - 2)")
                    .font(WSFont.label(9))
                    .bold()
                    .foregroundStyle(Color.wsNavy)
                    .frame(width: 26, height: 26)
                    .background(Color.wsControlFill)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 2)
            }
        }
    }
    
    private func avatarCircle(for user: FacepileUser) -> some View {
        Text(user.initials)
            .font(WSFont.label(9))
            .bold()
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(
                Circle()
                    .fill(user.color)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 2)
    }
}

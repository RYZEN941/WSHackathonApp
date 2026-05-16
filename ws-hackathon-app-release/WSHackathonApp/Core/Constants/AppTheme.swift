//
//  AppTheme.swift
//  WSHackathonApp
//

import SwiftUI

// MARK: - Williams Sonoma / Dormify-inspired palette (#FDFBF8)
extension Color {
    /// Site background — warm off-white
    static let wsBackground = Color(red: 253 / 255, green: 251 / 255, blue: 248 / 255)
    static let wsCard       = Color.white
    static let wsSurface    = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let wsBorder     = Color(red: 0.88, green: 0.85, blue: 0.80)

    static let wsCharcoal   = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let wsPrimary    = Color(red: 0.08, green: 0.12, blue: 0.16)
    static let wsAccent     = Color(red: 0.55, green: 0.38, blue: 0.28)
    static let wsAction     = Color.wsCharcoal
    static let wsControlFill = Color(red: 0.97, green: 0.95, blue: 0.92)

    static let wsNavy       = Color(red: 0.08, green: 0.12, blue: 0.16)
    static let wsText       = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let wsTextSecondary = Color(red: 0.45, green: 0.43, blue: 0.40)
    static let wsMuted      = Color(red: 0.62, green: 0.60, blue: 0.57)
    static let wsSuccess    = Color(red: 0.20, green: 0.60, blue: 0.40)
}

// MARK: - Gradients (warm neutrals only — no blue)

enum WSGradient {
    static let canvas = LinearGradient(
        colors: [
            Color.wsBackground,
            Color(red: 0.99, green: 0.97, blue: 0.94)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroOverlay = LinearGradient(
        colors: [
            Color.black.opacity(0.08),
            Color.clear,
            Color.black.opacity(0.50)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let button = LinearGradient(
        colors: [Color.wsCharcoal, Color(red: 0.18, green: 0.18, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonLight = LinearGradient(
        colors: [Color.white, Color(red: 0.98, green: 0.97, blue: 0.95)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accent = LinearGradient(
        colors: [Color.wsAccent, Color(red: 0.62, green: 0.44, blue: 0.30)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let card = LinearGradient(
        colors: [Color.white, Color.wsBackground],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardStroke = LinearGradient(
        colors: [
            Color.wsAccent.opacity(0.35),
            Color.wsBorder.opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let shimmerBar = LinearGradient(
        colors: [Color.wsCharcoal, Color.wsAccent.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - App background

struct WSAppBackground: View {
    var body: some View {
        Color.wsBackground
    }
}

extension View {
    func wsAppBackground() -> some View {
        background(WSAppBackground().ignoresSafeArea())
    }

    func wsPrimaryButtonBackground(cornerRadius: CGFloat = 14) -> some View {
        background(WSGradient.button)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func wsLightButtonBackground(cornerRadius: CGFloat = 4) -> some View {
        background(WSGradient.buttonLight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.wsBorder, lineWidth: 1)
            )
    }
}

// MARK: - Typography (clean sans + editorial serif)

struct WSFont {
    static func display(_ size: CGFloat = 36) -> Font {
        .custom("Optima-Bold", size: size)
    }

    static func heading(_ size: CGFloat = 22) -> Font {
        .custom("Optima-Regular", size: size)
    }

    static func label(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func subheading(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func price(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

// MARK: - Elegant Shadows

struct WSShadow {
    static let float = (
        color: Color.black.opacity(0.06),
        radius: CGFloat(20),
        x: CGFloat(0),
        y: CGFloat(10)
    )

    static let pop = (
        color: Color.black.opacity(0.08),
        radius: CGFloat(10),
        x: CGFloat(0),
        y: CGFloat(4)
    )

    static let glow = (
        color: Color.wsAccent.opacity(0.15),
        radius: CGFloat(12),
        x: CGFloat(0),
        y: CGFloat(6)
    )
}

// MARK: - Modifiers

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .init(x: phase - 0.5, y: 0),
                        endPoint: .init(x: phase + 0.5, y: 0)
                    )
                    .blendMode(.screen)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Motion

enum WSAnimation {
    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let quickSpring = Animation.spring(response: 0.28, dampingFraction: 0.86)
}

extension AnyTransition {
    static var wsControlInsert: AnyTransition {
        .scale(scale: 0.88, anchor: .trailing)
        .combined(with: .opacity)
    }

    static var wsControlRemove: AnyTransition {
        .scale(scale: 0.92, anchor: .trailing)
        .combined(with: .opacity)
    }

    static var wsBadgeInsert: AnyTransition {
        .move(edge: .leading)
        .combined(with: .opacity)
    }
}

// MARK: - Layout

enum WSSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum WSRadius {
    static let card: CGFloat = 14
    static let hero: CGFloat = 4
    static let pill: CGFloat = 999
}

// MARK: - Card surface

struct WSCardBackground: View {
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(WSGradient.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(WSGradient.cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct WSCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content.background(WSCardBackground(cornerRadius: cornerRadius))
    }
}

extension View {
    func wsCard(cornerRadius: CGFloat = 14) -> some View {
        modifier(WSCardStyle(cornerRadius: cornerRadius))
    }

    func wsCardBackground(cornerRadius: CGFloat = 14) -> some View {
        background(WSCardBackground(cornerRadius: cornerRadius))
    }
}

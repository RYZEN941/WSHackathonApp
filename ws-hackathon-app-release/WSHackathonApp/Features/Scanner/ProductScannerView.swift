//
//  ProductScannerView.swift
//  WSHackathonApp
//
//  SwiftUI wrapper — glassmorphic scanner UI + navigation callback.
//

import SwiftUI
import AVFoundation

// MARK: - UIViewController Representable

private struct ScannerRepresentable: UIViewControllerRepresentable {
    let controller: ProductScannerController

    func makeUIViewController(context: Context) -> ProductScannerController {
        controller
    }

    func updateUIViewController(_ uiViewController: ProductScannerController, context: Context) {}
}

// MARK: - ProductScannerView

struct ProductScannerView: View {

    // Called when any layer fires a match
    var onMatchFound: (ProductItem) -> Void

    @StateObject private var viewModel = ScannerViewModel()
    @State private var cameraController = ProductScannerController()
    @State private var showNoMatch = false
    @State private var scannerReady = false
    @Environment(\.dismiss) private var dismiss

    // Reticle animation
    @State private var reticlePulse = false

    var body: some View {
        ZStack {
            // ── Live camera feed ──────────────────────────────────────
            ScannerRepresentable(controller: cameraController)
                .ignoresSafeArea()

            // ── Glassmorphic overlay ──────────────────────────────────
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Central reticle
                reticleView

                Spacer()

                // Bottom controls
                bottomBar
            }

            // ── No-match toast ────────────────────────────────────────
            if showNoMatch {
                noMatchToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            bindController()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                scannerReady = true
            }
        }
        .onChange(of: viewModel.matchedProduct) { _, product in
            guard let product else { return }
            // Small delay for the UI state to animate, then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                onMatchFound(product)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 3) {
                Text("PRODUCT SCANNER")
                    .font(WSFont.label(11))
                    .tracking(3)
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(Color.wsAccent)
                    .frame(width: 20, height: 2)
            }

            Spacer()

            // Placeholder to balance layout
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Reticle

    private var reticleView: some View {
        VStack(spacing: 20) {
            // Square reticle frame
            ZStack {
                // Dimmed corners
                reticleCorners

                // Pulsing inner glow for scanning state
                if case .scanning = viewModel.state {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(reticlePulse ? 0.6 : 0.25),
                            lineWidth: 2
                        )
                        .frame(width: 240, height: 240)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                            value: reticlePulse
                        )
                        .onAppear { reticlePulse = true }
                }

                // State icon
                stateIcon
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(width: 240, height: 240)

            // State label
            stateLabel

            // Confidence bar (Layer 3 only)
            if case .objectIdentified(let conf) = viewModel.state {
                confidenceBar(value: conf)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(WSAnimation.spring, value: viewModel.state)
    }

    private var reticleCorners: some View {
        ZStack {
            // Top-left
            corner(rotation: 0)
                .offset(x: -104, y: -104)
            // Top-right
            corner(rotation: 90)
                .offset(x: 104, y: -104)
            // Bottom-right
            corner(rotation: 180)
                .offset(x: 104, y: 104)
            // Bottom-left
            corner(rotation: 270)
                .offset(x: -104, y: 104)
        }
    }

    private func corner(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 28))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 28, y: 0))
        }
        .stroke(cornerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 28, height: 28)
        .rotationEffect(.degrees(rotation))
    }

    private var cornerColor: Color {
        switch viewModel.state {
        case .barcodeDetected:  return Color.green
        case .labelRecognized:  return Color.wsAccent
        case .objectIdentified: return Color.orange
        default:                return Color.white
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch viewModel.state {
        case .scanning:
            Image(systemName: "viewfinder")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.white.opacity(0.4))
        case .barcodeDetected:
            successIcon(systemName: "barcode.viewfinder", color: .green)
        case .labelRecognized:
            successIcon(systemName: "textformat.abc", color: Color.wsAccent)
        case .objectIdentified:
            successIcon(systemName: "eye.fill", color: .orange)
        case .noMatch:
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.white.opacity(0.6))
        case .idle:
            EmptyView()
        }
    }

    private func successIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 12)
            Image(systemName: systemName)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(color)
                .symbolEffect(.bounce, value: viewModel.state)
        }
    }

    private var stateLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateDotColor)
                .frame(width: 7, height: 7)
                .opacity(viewModel.state == .scanning ? (reticlePulse ? 1 : 0.3) : 1)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: reticlePulse)

            Text(stateLabelText)
                .font(WSFont.subheading(15))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var stateLabelText: String {
        switch viewModel.state {
        case .scanning:         return "Scanning…"
        case .barcodeDetected:  return "⚡ Barcode detected"
        case .labelRecognized:  return "🔤 Label recognized"
        case .objectIdentified: return "🧠 Object identified"
        case .noMatch:          return "No product found"
        case .idle:             return ""
        }
    }

    private var stateDotColor: Color {
        switch viewModel.state {
        case .scanning:         return .white
        case .barcodeDetected:  return .green
        case .labelRecognized:  return Color.wsAccent
        case .objectIdentified: return .orange
        case .noMatch:          return .red
        case .idle:             return .gray
        }
    }

    private func confidenceBar(value: Float) -> some View {
        VStack(spacing: 6) {
            Text("Confidence: \(Int(value * 100))%")
                .font(WSFont.caption(11))
                .foregroundStyle(Color.white.opacity(0.7))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, Color.wsAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value))
                        .animation(WSAnimation.spring, value: value)
                }
            }
            .frame(height: 6)
            .frame(width: 180)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 16) {
            // Simulate Scan (demo safety net)
            Button {
                viewModel.simulateScan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Simulate Scan")
                        .font(WSFont.subheading(15))
                }
                .foregroundStyle(Color.wsNavy)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())

            Text("Point camera at any Williams Sonoma product")
                .font(WSFont.caption(11))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - No-match toast

    private var noMatchToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                Text("No product found — try again")
                    .font(WSFont.body(14))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .padding(.bottom, 120)
        }
    }

    // MARK: - Bind controller callbacks

    private func bindController() {
        cameraController.delegate = Coordinator(viewModel: viewModel)

        // Wire throttle checks back to ViewModel (on vision queue, so capture values)
        cameraController.onRequestShouldRunOCR = { [weak vm = viewModel] in
            vm?.shouldRunOCR ?? false
        }
        cameraController.onRequestShouldRunML = { [weak vm = viewModel] in
            vm?.shouldRunML ?? false
        }
        cameraController.onMarkOCRRan = { [weak vm = viewModel] in
            Task { @MainActor in vm?.markOCRRan() }
        }
        cameraController.onMarkMLRan = { [weak vm = viewModel] in
            Task { @MainActor in vm?.markMLRan() }
        }
    }

    // MARK: - Coordinator (delegate bridge)

    private class Coordinator: ProductScannerControllerDelegate {
        private let vm: ScannerViewModel
        init(viewModel: ScannerViewModel) { self.vm = viewModel }

        func scannerDidDetectBarcode(_ code: String) {
            Task { @MainActor in vm.handleBarcode(code) }
        }
        func scannerDidDetectText(_ text: String) {
            Task { @MainActor in vm.handleOCRText(text) }
        }
        func scannerDidClassifyObject(label: String, confidence: Float) {
            Task { @MainActor in vm.handleMLLabel(label, confidence: confidence) }
        }
    }
}

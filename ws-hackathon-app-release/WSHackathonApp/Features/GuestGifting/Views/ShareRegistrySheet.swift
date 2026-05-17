//
//  ShareRegistrySheet.swift
//  WSHackathonApp
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ShareRegistrySheet: View {
    let registryName: String
    let shareCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var deepLink: String {
        "wshackathon://registry/\(shareCode)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Share Your Registry")
                            .font(WSFont.heading(26))
                            .foregroundStyle(Color.wsNavy)
                            .multilineTextAlignment(.center)
                        Text("Guests can scan the QR code or open the link to view and gift items — no account needed.")
                            .font(WSFont.body(14))
                            .foregroundStyle(Color.wsTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)

                    qrCodeCard

                    VStack(spacing: 12) {
                        // Copy Link
                        Button {
                            UIPasteboard.general.string = deepLink
                            withAnimation(WSAnimation.quickSpring) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(WSAnimation.quickSpring) { copied = false }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: copied ? "checkmark.circle.fill" : "link")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(copied ? "Link Copied!" : "Copy Link")
                                    .font(WSFont.subheading(16))
                            }
                            .foregroundStyle(copied ? Color.wsSuccess : Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                copied
                                    ? AnyShapeStyle(Color.wsSuccess.opacity(0.12))
                                    : AnyShapeStyle(WSGradient.button)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(copied ? Color.wsSuccess.opacity(0.4) : Color.clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .animation(WSAnimation.spring, value: copied)

                        // Share via system sheet
                        ShareLink(item: deepLink,
                                  subject: Text("My \(registryName) Registry"),
                                  message: Text("Open this link to view our registry and gift something special 🎁")) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Share via…")
                                    .font(WSFont.subheading(16))
                            }
                            .foregroundStyle(Color.wsNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.wsBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.wsBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Deep link preview pill
                    HStack(spacing: 6) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.wsAccent)
                        Text(deepLink)
                            .font(WSFont.caption(12))
                            .foregroundStyle(Color.wsTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.wsSurface)
                    .clipShape(Capsule(style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(WSFont.body(15))
                        .foregroundStyle(Color.wsNavy)
                }
            }
        }
    }

    // MARK: - QR Code Card

    private var qrCodeCard: some View {
        VStack(spacing: 16) {
            if let qrImage = generateQRCode(from: deepLink) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.07), radius: 12, y: 6)
            }

            VStack(spacing: 4) {
                Text(registryName)
                    .font(WSFont.subheading(17))
                    .foregroundStyle(Color.wsNavy)
                Text("Registry Code: \(shareCode)")
                    .font(WSFont.caption(13))
                    .foregroundStyle(Color.wsTextSecondary)
                    .tracking(1.5)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(WSCardBackground(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    // MARK: - QR Generation (CoreImage)

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

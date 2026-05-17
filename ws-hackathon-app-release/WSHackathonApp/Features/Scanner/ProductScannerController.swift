//
//  ProductScannerController.swift
//  WSHackathonApp
//
//  UIKit AVCaptureSession controller — wraps all 3 detection layers.
//  Owned by ProductScannerView via UIViewControllerRepresentable.
//

import UIKit
import AVFoundation
import Vision

// MARK: - Delegate

protocol ProductScannerControllerDelegate: AnyObject {
    func scannerDidDetectBarcode(_ code: String)
    func scannerDidDetectText(_ text: String)
    func scannerDidClassifyObject(label: String, confidence: Float)
}

// MARK: - Controller

final class ProductScannerController: UIViewController {

    weak var delegate: ProductScannerControllerDelegate?

    // AVFoundation
    private let session        = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private let sessionQueue   = DispatchQueue(label: "scanner.session", qos: .userInitiated)
    private let visionQueue    = DispatchQueue(label: "scanner.vision", qos: .utility)

    // Preview
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // Throttling
    var shouldRunOCR: Bool = true
    var shouldRunML: Bool  = true
    var onRequestShouldRunOCR: (() -> Bool)?
    var onRequestShouldRunML:  (() -> Bool)?
    var onMarkOCRRan: (() -> Void)?
    var onMarkMLRan:  (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    // MARK: - Session Setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        // Input
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // Layer 1 — Barcode
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            let supported: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .qr, .code128, .code39, .upce]
            metadataOutput.metadataObjectTypes = supported.filter {
                metadataOutput.availableMetadataObjectTypes.contains($0)
            }
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        }

        // Layer 2 + 3 — Video frames for Vision
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        // Preview layer (must be added on main thread)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = self.view.bounds
            self.view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
    }
}

// MARK: - Layer 1: AVCaptureMetadataOutputObjectsDelegate (Barcode)

extension ProductScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let obj   = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = obj.stringValue,
            !value.isEmpty
        else { return }

        delegate?.scannerDidDetectBarcode(value)
    }
}

// MARK: - Layer 2 + 3: AVCaptureVideoDataOutputSampleBufferDelegate

extension ProductScannerController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var requests: [VNRequest] = []

        // Layer 2 — OCR
        if onRequestShouldRunOCR?() ?? true {
            onMarkOCRRan?()
            let ocrRequest = VNRecognizeTextRequest { [weak self] req, _ in
                guard let self else { return }
                let text = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ") ?? ""
                guard !text.isEmpty else { return }
                DispatchQueue.main.async {
                    self.delegate?.scannerDidDetectText(text)
                }
            }
            ocrRequest.recognitionLevel = .fast
            ocrRequest.usesLanguageCorrection = false
            requests.append(ocrRequest)
        }

        // Layer 3 — CoreML (Vision built-in image classification — no .mlmodel file needed)
        if onRequestShouldRunML?() ?? true {
            onMarkMLRan?()
            // Use VNClassifyImageRequest which uses Apple's on-device model
            let classRequest = VNClassifyImageRequest { [weak self] req, _ in
                guard let self else { return }
                guard
                    let observations = req.results as? [VNClassificationObservation],
                    let top = observations.first,
                    top.confidence >= 0.4
                else { return }
                DispatchQueue.main.async {
                    self.delegate?.scannerDidClassifyObject(
                        label: top.identifier,
                        confidence: top.confidence
                    )
                }
            }
            requests.append(classRequest)
        }

        guard !requests.isEmpty else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform(requests)
    }
}

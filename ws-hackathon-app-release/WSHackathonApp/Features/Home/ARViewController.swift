//
//  ARViewController.swift
//  WSHackathonApp
//
//  Created on 17/05/26.
//

import UIKit
import ARKit
import RealityKit

class ARViewController: UIViewController {
    
    // Core AR State
    var arView: ARView!
    var instructionLabel: UILabel!
    
    let modelName: String      // The USDZ file name
    let productTitle: String   // The product name 
    
    // Track placed anchors
    private var placedAnchors: [AnchorEntity] = []
    private var placementCount: Int = 0 {
        didSet { updatePlacementBadge() }
    }
    
    // Custom UI Components
    private let loadingSpinner = UIActivityIndicatorView(style: .large)
    private let spinnerContainer = UIView()
    private let placementBadge = UIView()
    private let placementBadgeLabel = UILabel()
    private var instructionHideTimer: DispatchWorkItem?
    
    init(modelName: String, productTitle: String) {
        self.modelName = modelName
        self.productTitle = productTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupUI()
        setupGestures()
        setupCoachingOverlay()
        
        showInstruction("Move device slowly to detect surfaces, then tap to place \(productTitle)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - AR Setup & Coaching
    
    private func setupARView() {
        arView = ARView(frame: .zero)
        arView.translatesAutoresizingMaskIntoConstraints = false
        arView.automaticallyConfigureSession = false
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupCoachingOverlay() {
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        coaching.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coaching)
        
        NSLayoutConstraint.activate([
            coaching.topAnchor.constraint(equalTo: arView.topAnchor),
            coaching.bottomAnchor.constraint(equalTo: arView.bottomAnchor),
            coaching.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coaching.trailingAnchor.constraint(equalTo: arView.trailingAnchor)
        ])
    }
    
    // MARK: - Programmatic UI Layout
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Navigation / Header view
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(headerView)
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "AR Visualize"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        // Back Button
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        headerView.addSubview(backButton)
        
        // Trash (Clear All) Button
        let trashButton = UIButton(type: .system)
        trashButton.translatesAutoresizingMaskIntoConstraints = false
        trashButton.setImage(UIImage(systemName: "trash"), for: .normal)
        trashButton.tintColor = .systemRed
        trashButton.addTarget(self, action: #selector(clearAllModels), for: .touchUpInside)
        headerView.addSubview(trashButton)
        
        // Instruction Label
        instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        instructionLabel.numberOfLines = 0
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        instructionLabel.layer.cornerRadius = 10
        instructionLabel.layer.masksToBounds = true
        view.addSubview(instructionLabel)
        
        // Loading Spinner Container
        spinnerContainer.translatesAutoresizingMaskIntoConstraints = false
        spinnerContainer.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        spinnerContainer.layer.cornerRadius = 16
        spinnerContainer.isHidden = true
        view.addSubview(spinnerContainer)
        
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinner.color = .white
        spinnerContainer.addSubview(loadingSpinner)
        
        // Placement Badge
        placementBadge.translatesAutoresizingMaskIntoConstraints = false
        placementBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        placementBadge.layer.cornerRadius = 12
        placementBadge.isHidden = true
        view.addSubview(placementBadge)
        
        placementBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        placementBadgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        placementBadgeLabel.textColor = .white
        placementBadgeLabel.textAlignment = .center
        placementBadge.addSubview(placementBadgeLabel)
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            trashButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            trashButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            trashButton.widthAnchor.constraint(equalToConstant: 44),
            trashButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Instruction Label
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            // Spinner
            spinnerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinnerContainer.widthAnchor.constraint(equalToConstant: 80),
            spinnerContainer.heightAnchor.constraint(equalToConstant: 80),
            
            loadingSpinner.centerXAnchor.constraint(equalTo: spinnerContainer.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: spinnerContainer.centerYAnchor),
            
            // Placement Badge
            placementBadge.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            placementBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            placementBadge.heightAnchor.constraint(equalToConstant: 24),
            
            placementBadgeLabel.leadingAnchor.constraint(equalTo: placementBadge.leadingAnchor, constant: 8),
            placementBadgeLabel.trailingAnchor.constraint(equalTo: placementBadge.trailingAnchor, constant: -8),
            placementBadgeLabel.centerYAnchor.constraint(equalTo: placementBadge.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    private func updatePlacementBadge() {
        if placementCount == 0 {
            placementBadge.isHidden = true
        } else {
            placementBadge.isHidden = false
            placementBadgeLabel.text = "\(placementCount) placed"
        }
    }
    
    // MARK: - Gestures & Interactions
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        arView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: arView)
        let results = arView.raycast(from: loc, allowing: .estimatedPlane, alignment: .horizontal)
        guard let first = results.first else {
            showInstruction("No surface detected — move device slowly to scan")
            return
        }
        placeModel(at: first)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let loc = gesture.location(in: arView)
        if let hit = arView.entity(at: loc) {
            removeModelContaining(entity: hit)
        }
    }
    
    // MARK: - Placement Logic
    
    private func placeModel(at result: ARRaycastResult) {
        let anchor = AnchorEntity(world: result.worldTransform)
        arView.scene.addAnchor(anchor)
        
        showLoadingSpinner(true)
        showInstruction("Loading 3D model…")
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let entity = try await ModelEntity.loadModelAsync(named: self.modelName)
                
                await MainActor.run {
                    self.showLoadingSpinner(false)
                    
                    // Auto-scale to physical 30 cm dimension
                    let ext = entity.model?.mesh.bounds.extents ?? .one
                    let maxDim = max(ext.x, ext.y, ext.z)
                    entity.scale = SIMD3<Float>(repeating: maxDim > 0 ? 0.3 / maxDim : 1.0)
                    
                    entity.generateCollisionShapes(recursive: true)
                    anchor.addChild(entity)
                    
                    // Install RealityKit translation, rotation, scaling gestures
                    self.arView.installGestures([.translation, .rotation, .scale], for: entity)
                    
                    self.placedAnchors.append(anchor)
                    self.placementCount += 1
                    
                    self.showInstruction("Placed! Drag to move, pinch to scale, or long-press to remove.", autohide: 4)
                }
            } catch {
                await MainActor.run {
                    self.showLoadingSpinner(false)
                    self.arView.scene.removeAnchor(anchor)
                    self.showInstruction("Could not load AR model. Try again.", autohide: 3)
                    print("AR Model Placement Error: \(error)")
                }
            }
        }
    }
    
    private func removeModelContaining(entity: Entity) {
        let alert = UIAlertController(
            title: "Remove Model?",
            message: "Remove this 3D model from the environment?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self else { return }
            
            // Find root anchor of the entity
            var current: Entity? = entity
            while let e = current {
                if let anchor = e as? AnchorEntity, self.placedAnchors.contains(anchor) {
                    self.arView.scene.removeAnchor(anchor)
                    self.placedAnchors.removeAll(where: { $0 == anchor })
                    self.placementCount -= 1
                    self.showInstruction("Model removed", autohide: 2)
                    break
                }
                current = e.parent
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func clearAllModels() {
        guard !placedAnchors.isEmpty else {
            showInstruction("No models placed yet", autohide: 2)
            return
        }
        
        let alert = UIAlertController(
            title: "Clear Environment?",
            message: "Remove all \(placedAnchors.count) placed model(s)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.placedAnchors.forEach { self.arView.scene.removeAnchor($0) }
            self.placedAnchors.removeAll()
            self.placementCount = 0
            self.showInstruction("Environment cleared", autohide: 2)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Helpers
    
    private func showLoadingSpinner(_ visible: Bool) {
        spinnerContainer.isHidden = !visible
        visible ? loadingSpinner.startAnimating() : loadingSpinner.stopAnimating()
    }
    
    private func showInstruction(_ text: String, autohide seconds: Double? = nil) {
        instructionHideTimer?.cancel()
        instructionHideTimer = nil
        
        instructionLabel.alpha = 1
        instructionLabel.text = text
        
        if let delay = seconds {
            let work = DispatchWorkItem { [weak self] in
                UIView.animate(withDuration: 0.5) { self?.instructionLabel.alpha = 0 }
            }
            instructionHideTimer = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }
}

// MARK: - RealityKit Async Extensions

extension ModelEntity {
    static func loadModelAsync(named name: String) async throws -> ModelEntity {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else {
            throw NSError(domain: "ARModelError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model \(name).usdz not found in bundle."])
        }
        
        return try await Task.detached(priority: .userInitiated) {
            let loadedEntity = try Entity.load(contentsOf: url)
            guard let modelEntity = loadedEntity as? ModelEntity else {
                if let firstModel = loadedEntity.findModelEntity() {
                    return firstModel
                }
                throw NSError(domain: "ARModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Loaded entity is not a ModelEntity."])
            }
            return modelEntity
        }.value
    }
}

extension Entity {
    func findModelEntity() -> ModelEntity? {
        if let model = self as? ModelEntity {
            return model
        }
        for child in children {
            if let found = child.findModelEntity() {
                return found
            }
        }
        return nil
    }
}

//
//  DrawingEditorView.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/06/25.
//
//

import SwiftUI
import PencilKit
import CoreData

struct DrawingEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = UserSettings()
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    // Drawing to edit (nil for new drawing) - Using NSManagedObjectID instead of Drawing entity
    let drawingID: NSManagedObjectID?
    @State private var drawingTitle: String = ""
    @State private var hasUnsavedChanges = false
    @State private var showingSaveDialog = false
    
    // Size class for adaptive UI
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Available colors for quick selection
    let availableColors: [Color] = [.black, .blue, .red, .green, .orange, .purple, .pink, .brown]
    let availableLineWidths: [CGFloat] = [1.0, 3.0, 5.0, 8.0, 12.0, 20.0]
    
    // Initializer for new drawing
    init() {
        self.drawingID = nil
    }
    
    // Initializer for editing existing drawing
    init(drawingID: NSManagedObjectID) {
        self.drawingID = drawingID
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Main Canvas
                    DrawingCanvasView(
                        canvasView: $canvasView,
                        toolPicker: $toolPicker,
                        selectedColor: $settings.selectedColor,
                        selectedLineWidth: $settings.selectedLineWidth,
                        isEraserActive: $settings.isEraserActive,
                        canvasScale: $settings.canvasScale,
                        canvasOffset: $settings.canvasOffset,
                        onDrawingChange: {
                            hasUnsavedChanges = true
                        }
                    )
                    
                    // Adaptive Toolbar
                    if settings.showingToolbar {
                        toolbarView(for: geometry)
                    }
                }
            }
            .navigationBarTitle(adaptiveTitle, displayMode: .inline)
            .navigationBarItems(
                leading: leadingBarItems,
                trailing: trailingBarItems
            )
            .onAppear(perform: setupView)
            .alert("Save Drawing", isPresented: $showingSaveDialog) {
                TextField("Drawing Title", text: $drawingTitle)
                Button("Save") {
                    saveDrawing()
                }
                Button("Don't Save", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for your drawing")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Adaptive Title
    private var adaptiveTitle: String {
        if horizontalSizeClass == .compact {
            return "Draw"
        }
        return drawingTitle.isEmpty ? "New Drawing" : drawingTitle
    }
    
    // MARK: - Adaptive Toolbar View
    @ViewBuilder
    private func toolbarView(for geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        if isLandscape || horizontalSizeClass == .regular {
            HStack {
                customToolbar
                    .frame(maxWidth: 80)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.leading, 16)
                    .padding(.vertical, 16)
                
                Spacer()
            }
        } else {
            VStack {
                Spacer()
                
                customToolbar
                    .frame(maxHeight: 80)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Custom Toolbar
    private var customToolbar: some View {
        let isLandscape = horizontalSizeClass == .regular || verticalSizeClass == .compact
        
        return Group {
            if isLandscape {
                VStack(spacing: 12) {
                    toolbarContent
                }
                .padding(.vertical, 12)
            } else {
                HStack(spacing: 12) {
                    toolbarContent
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    @ViewBuilder
    private var toolbarContent: some View {
        // Color Picker
        Menu {
            ForEach(availableColors, id: \.self) { color in
                Button(action: {
                    selectColor(color)
                }) {
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                        Text(colorName(for: color))
                        if settings.selectedColor == color {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Circle()
                .fill(settings.selectedColor)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
        }
        .keyboardShortcut("c", modifiers: .command)
        
        Divider()
            .frame(width: 1, height: 30)
        
        // Line Width Picker
        Menu {
            ForEach(availableLineWidths, id: \.self) { width in
                Button(action: {
                    selectLineWidth(width)
                }) {
                    HStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: width, height: width)
                        Text("\(Int(width))pt")
                        if settings.selectedLineWidth == width {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(Color.primary)
                    .frame(width: settings.selectedLineWidth, height: settings.selectedLineWidth)
            }
        }
        .keyboardShortcut("w", modifiers: .command)
        
        Divider()
            .frame(width: 1, height: 30)
        
        // Eraser Toggle
        Button(action: toggleEraser) {
            Image(systemName: settings.isEraserActive ? "eraser.fill" : "eraser")
                .font(.title2)
                .foregroundColor(settings.isEraserActive ? .red : .primary)
                .frame(width: 40, height: 40)
                .background(settings.isEraserActive ? Color.red.opacity(0.1) : Color.clear)
                .cornerRadius(8)
        }
        .keyboardShortcut("e", modifiers: .command)
        
        Divider()
            .frame(width: 1, height: 30)
        
        // Zoom Reset
        Button(action: resetZoom) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.title2)
                .frame(width: 40, height: 40)
        }
        .keyboardShortcut("0", modifiers: .command)
    }
    
    // MARK: - Navigation Bar Items
    private var leadingBarItems: some View {
        HStack(spacing: 16) {
            Button(action: closeDrawing) {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.cancelAction)
            
            Button(action: clearCanvas) {
                Label("Clear", systemImage: "trash")
            }
            .keyboardShortcut("k", modifiers: .command)
            
            Button(action: toggleToolbar) {
                Label(
                    settings.showingToolbar ? "Hide Tools" : "Show Tools",
                    systemImage: settings.showingToolbar ? "eye.slash" : "eye"
                )
            }
            .keyboardShortcut("t", modifiers: .command)
        }
    }
    
    private var trailingBarItems: some View {
        HStack(spacing: 16) {
            if horizontalSizeClass == .regular {
                Text("\(Int(settings.canvasScale * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: undo) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(canvasView.undoManager?.canUndo != true)
            
            Button(action: redo) {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(canvasView.undoManager?.canRedo != true)
            
            Button(action: saveDrawing) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!hasUnsavedChanges && drawingID != nil)
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        // Load existing drawing if editing
        if let drawingID = drawingID {
            let context = PersistenceController.shared.container.viewContext
            if let drawingEntity = try? context.existingObject(with: drawingID) as? NSManagedObject {
                drawingTitle = drawingEntity.value(forKey: "title") as? String ?? "Untitled"
                if let drawingData = drawingEntity.value(forKey: "drawingData") as? Data,
                   let loadedDrawing = try? PKDrawing(data: drawingData) {
                    canvasView.drawing = loadedDrawing
                }
            }
        } else {
            drawingTitle = "Untitled"
        }
        
        updateCanvasTool()
    }
    
    // MARK: - Tool Actions
    private func selectColor(_ color: Color) {
        settings.selectedColor = color
        settings.isEraserActive = false
        updateCanvasTool()
    }
    
    private func selectLineWidth(_ width: CGFloat) {
        settings.selectedLineWidth = width
        settings.isEraserActive = false
        updateCanvasTool()
    }
    
    private func toggleEraser() {
        settings.isEraserActive.toggle()
        updateCanvasTool()
    }
    
    private func updateCanvasTool() {
        if settings.isEraserActive {
            let eraser = PKEraserTool(.vector)
            canvasView.tool = eraser
        } else {
            let ink = PKInkingTool(.pen, color: UIColor(settings.selectedColor), width: settings.selectedLineWidth)
            canvasView.tool = ink
        }
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        hasUnsavedChanges = true
    }
    
    private func undo() {
        canvasView.undoManager?.undo()
        hasUnsavedChanges = true
    }
    
    private func redo() {
        canvasView.undoManager?.redo()
        hasUnsavedChanges = true
    }
    
    private func toggleToolbar() {
        withAnimation {
            settings.showingToolbar.toggle()
        }
    }
    
    private func resetZoom() {
        withAnimation {
            settings.canvasScale = 1.0
            settings.canvasOffset = .zero
        }
    }
    
    // MARK: - Save and Close
    private func saveDrawing() {
        if drawingID == nil {
            // New drawing - show dialog if no title
            if drawingTitle.isEmpty || drawingTitle == "Untitled" {
                showingSaveDialog = true
                return
            }
        }
        
        // Save the drawing
        if let existingDrawingID = drawingID {
            let context = PersistenceController.shared.container.viewContext
            if let drawingEntity = try? context.existingObject(with: existingDrawingID) as? NSManagedObject {
                drawingEntity.setValue(canvasView.drawing.dataRepresentation(), forKey: "drawingData")
                drawingEntity.setValue(Date(), forKey: "modifiedDate")
                
                // Update thumbnail
                if let thumbnail = generateThumbnail(from: canvasView.drawing) {
                    drawingEntity.setValue(thumbnail, forKey: "thumbnail")
                }
                
                try? context.save()
            }
        } else {
            PersistenceController.shared.saveDrawing(canvasView.drawing, title: drawingTitle)
        }
        
        hasUnsavedChanges = false
        dismiss()
    }
    
    private func closeDrawing() {
        if hasUnsavedChanges {
            showingSaveDialog = true
        } else {
            dismiss()
        }
    }
    
    // MARK: - Helper Functions
    private func colorName(for color: Color) -> String {
        switch color {
        case .black: return "Black"
        case .blue: return "Blue"
        case .red: return "Red"
        case .green: return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .brown: return "Brown"
        default: return "Custom"
        }
    }
    
    private func generateThumbnail(from drawing: PKDrawing) -> Data? {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        
        let thumbnailRect = CGRect(origin: .zero, size: thumbnailSize)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        image.draw(in: thumbnailRect)
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail?.pngData()
    }
}

// MARK: - Canvas View with Change Detection (Renamed to avoid conflicts)
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraserActive: Bool
    @Binding var canvasScale: CGFloat
    @Binding var canvasOffset: CGSize
    
    var onDrawingChange: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.alwaysBounceVertical = true
        canvasView.backgroundColor = .systemBackground
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 3.0
        canvasView.minimumZoomScale = 0.5
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        setupTrackpadGestures(for: canvasView, coordinator: context.coordinator)
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.zoomScale = canvasScale
        uiView.contentOffset = CGPoint(x: canvasOffset.width, y: canvasOffset.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupTrackpadGestures(for view: PKCanvasView, coordinator: Coordinator) {
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = coordinator
        view.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = coordinator
        view.addGestureRecognizer(panGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleRotation(_:)))
        rotationGesture.delegate = coordinator
        view.addGestureRecognizer(rotationGesture)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
        var parent: DrawingCanvasView
        private var initialScale: CGFloat = 1.0
        private var initialOffset: CGSize = .zero

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChange()
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                initialScale = parent.canvasScale
            case .changed:
                let newScale = initialScale * gesture.scale
                parent.canvasScale = min(max(newScale, 0.5), 3.0)
            default:
                break
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            
            switch gesture.state {
            case .began:
                initialOffset = parent.canvasOffset
            case .changed:
                let translation = gesture.translation(in: view)
                parent.canvasOffset = CGSize(
                    width: initialOffset.width - translation.x,
                    height: initialOffset.height - translation.y
                )
            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            if gesture.state == .changed {
                print("Rotation detected: \(gesture.rotation) radians")
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

//
//  DrawingView.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/06/25.
//
//

import SwiftUI
import PencilKit

struct DrawingView: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var selectedColor: Color = .black
    @State private var selectedLineWidth: CGFloat = 5.0
    @State private var isEraserActive: Bool = false
    @State private var showingToolbar: Bool = true
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    
    // Size class for adaptive UI
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Available colors for quick selection
    let availableColors: [Color] = [.black, .blue, .red, .green, .orange, .purple, .pink, .brown]
    let availableLineWidths: [CGFloat] = [1.0, 3.0, 5.0, 8.0, 12.0, 20.0]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Main Canvas
                    CanvasView(
                        canvasView: $canvasView,
                        toolPicker: $toolPicker,
                        selectedColor: $selectedColor,
                        selectedLineWidth: $selectedLineWidth,
                        isEraserActive: $isEraserActive,
                        canvasScale: $canvasScale,
                        canvasOffset: $canvasOffset
                    )
                    
                    // Adaptive Toolbar - Position changes based on size class
                    if showingToolbar {
                        toolbarView(for: geometry)
                    }
                }
            }
            .navigationBarTitle(adaptiveTitle, displayMode: .inline)
            .navigationBarItems(
                leading: leadingBarItems,
                trailing: trailingBarItems
            )
            .onAppear(perform: setupToolPicker)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Adaptive Title
    private var adaptiveTitle: String {
        // Shorter title for compact width
        if horizontalSizeClass == .compact {
            return "Draw"
        }
        return "Drawing Pad"
    }
    
    // MARK: - Adaptive Toolbar View
    @ViewBuilder
    private func toolbarView(for geometry: GeometryProxy) -> some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        let isLandscape = geometry.size.width > geometry.size.height
        
        if isLandscape || horizontalSizeClass == .regular {
            // Side toolbar for landscape or regular width
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
            // Bottom toolbar for portrait compact
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
                        if selectedColor == color {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Circle()
                .fill(selectedColor)
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
                        if selectedLineWidth == width {
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
                    .frame(width: selectedLineWidth, height: selectedLineWidth)
            }
        }
        .keyboardShortcut("w", modifiers: .command)
        
        Divider()
            .frame(width: 1, height: 30)
        
        // Eraser Toggle
        Button(action: toggleEraser) {
            Image(systemName: isEraserActive ? "eraser.fill" : "eraser")
                .font(.title2)
                .foregroundColor(isEraserActive ? .red : .primary)
                .frame(width: 40, height: 40)
                .background(isEraserActive ? Color.red.opacity(0.1) : Color.clear)
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
            Button(action: clearCanvas) {
                Label("Clear", systemImage: "trash")
            }
            .keyboardShortcut("k", modifiers: .command)
            
            Button(action: toggleToolbar) {
                Label(
                    showingToolbar ? "Hide Tools" : "Show Tools",
                    systemImage: showingToolbar ? "eye.slash" : "eye"
                )
            }
            .keyboardShortcut("t", modifiers: .command)
        }
    }
    
    private var trailingBarItems: some View {
        HStack(spacing: 16) {
            // Zoom info (only show in regular width)
            if horizontalSizeClass == .regular {
                Text("\(Int(canvasScale * 100))%")
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
        }
    }
    
    // MARK: - Setup
    private func setupToolPicker() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        // Set initial tool
        updateCanvasTool()
    }
    
    // MARK: - Tool Actions
    private func selectColor(_ color: Color) {
        selectedColor = color
        isEraserActive = false
        updateCanvasTool()
    }
    
    private func selectLineWidth(_ width: CGFloat) {
        selectedLineWidth = width
        isEraserActive = false
        updateCanvasTool()
    }
    
    private func toggleEraser() {
        isEraserActive.toggle()
        updateCanvasTool()
    }
    
    private func updateCanvasTool() {
        if isEraserActive {
            let eraser = PKEraserTool(.vector)
            canvasView.tool = eraser
        } else {
            let ink = PKInkingTool(.pen, color: UIColor(selectedColor), width: selectedLineWidth)
            canvasView.tool = ink
        }
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    private func undo() {
        canvasView.undoManager?.undo()
    }
    
    private func redo() {
        canvasView.undoManager?.redo()
    }
    
    private func toggleToolbar() {
        withAnimation {
            showingToolbar.toggle()
        }
    }
    
    private func resetZoom() {
        withAnimation {
            canvasScale = 1.0
            canvasOffset = .zero
        }
    }
    
    // MARK: - Helper
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
}

// MARK: - Canvas View with Trackpad Support
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraserActive: Bool
    @Binding var canvasScale: CGFloat
    @Binding var canvasOffset: CGSize

    func makeUIView(context: Context) -> PKCanvasView {
        // Configure PencilKit canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.alwaysBounceVertical = true
        canvasView.backgroundColor = .systemBackground
        
        // Enable multitasking optimizations
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 3.0
        canvasView.minimumZoomScale = 0.5
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        // Add trackpad gesture recognizers
        setupTrackpadGestures(for: canvasView, coordinator: context.coordinator)
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update zoom and offset
        uiView.zoomScale = canvasScale
        uiView.contentOffset = CGPoint(x: canvasOffset.width, y: canvasOffset.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Trackpad Gesture Setup
    private func setupTrackpadGestures(for view: PKCanvasView, coordinator: Coordinator) {
        // Pinch to zoom gesture (trackpad)
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = coordinator
        view.addGestureRecognizer(pinchGesture)
        
        // Two-finger pan gesture (trackpad)
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = coordinator
        view.addGestureRecognizer(panGesture)
        
        // Rotation gesture (trackpad)
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleRotation(_:)))
        rotationGesture.delegate = coordinator
        view.addGestureRecognizer(rotationGesture)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
        var parent: CanvasView
        private var initialScale: CGFloat = 1.0
        private var initialOffset: CGSize = .zero

        init(_ parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            print("Drawing updated – strokes count: \(canvasView.drawing.strokes.count)")
        }
        
        // MARK: - Trackpad Gesture Handlers
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view as? PKCanvasView else { return }
            
            switch gesture.state {
            case .began:
                initialScale = parent.canvasScale
            case .changed:
                let newScale = initialScale * gesture.scale
                parent.canvasScale = min(max(newScale, 0.5), 3.0)
            case .ended, .cancelled:
                break
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
            case .ended, .cancelled:
                break
            default:
                break
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            // Optional: implement canvas rotation if desired
            // For now, we'll just print the rotation for demonstration
            if gesture.state == .changed {
                print("Rotation detected: \(gesture.rotation) radians")
            }
        }
        
        // MARK: - UIGestureRecognizerDelegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow multiple gestures to be recognized simultaneously
            return true
        }
    }
}

// MARK: - SwiftUI Preview
struct DrawingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Portrait preview
            DrawingView()
                .previewInterfaceOrientation(.portrait)
                .previewDisplayName("Portrait")
            
            // Landscape preview
            DrawingView()
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape")
            
            // Split View simulation (compact width)
            DrawingView()
                .previewInterfaceOrientation(.portrait)
                .environment(\.horizontalSizeClass, .compact)
                .previewDisplayName("Split View")
        }
    }
}

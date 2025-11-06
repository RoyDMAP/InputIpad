//
//  DrawingView.swift
//  Input Ipad
//
//  Created by Gaby Sanchez on 10/15/25.
//

import SwiftUI
import PencilKit

struct DrawingView: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CanvasView(canvasView: $canvasView, toolPicker: $toolPicker)
                    .navigationBarTitle("Drawing Pad", displayMode: .inline)
                    .navigationBarItems(
                        leading: HStack {
                            Button(action: clearCanvas) {
                                Label("Clear", systemImage: "trash")
                            }
                            .keyboardShortcut("k", modifiers: .command)
                        },
                        trailing: HStack(spacing: 20) {
                            Button(action: undo) {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .keyboardShortcut("z", modifiers: .command) // ⌘Z
                            
                            Button(action: redo) {
                                Label("Redo", systemImage: "arrow.uturn.forward")
                            }
                            .keyboardShortcut("z", modifiers: [.command, .shift]) // ⇧⌘Z
                        }
                    )
                    .onAppear(perform: setupToolPicker)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    private func setupToolPicker() {
        // Set up and show the tool picker for Apple Pencil
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
    }
    
    private func clearCanvas() {
        // Clears the entire drawing
        canvasView.drawing = PKDrawing()
    }

    private func undo() {
        // Undo the last drawing stroke
        canvasView.undoManager?.undo()
    }

    private func redo() {
        // Redo the last undone stroke
        canvasView.undoManager?.redo()
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        // Configure PencilKit canvas
        canvasView.drawingPolicy = .anyInput // Allows Apple Pencil and finger
        canvasView.delegate = context.coordinator
        canvasView.alwaysBounceVertical = true
        canvasView.backgroundColor = .systemBackground
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView

        init(_ parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Called when the user draws something new
            print("Drawing updated – strokes count: \(canvasView.drawing.strokes.count)")
        }
    }
}

// MARK: - SwiftUI Preview
struct DrawingView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

//
//  UserSettings.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/06/25.
//

import SwiftUI

class UserSettings: ObservableObject {
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let selectedColorRed = "selectedColorRed"
        static let selectedColorGreen = "selectedColorGreen"
        static let selectedColorBlue = "selectedColorBlue"
        static let selectedColorAlpha = "selectedColorAlpha"
        static let selectedLineWidth = "selectedLineWidth"
        static let isEraserActive = "isEraserActive"
        static let showingToolbar = "showingToolbar"
        static let canvasScale = "canvasScale"
        static let canvasOffsetWidth = "canvasOffsetWidth"
        static let canvasOffsetHeight = "canvasOffsetHeight"
        static let lastDrawingID = "lastDrawingID"
    }
    
    // MARK: - Selected Color
    @Published var selectedColor: Color {
        didSet {
            saveColor(selectedColor)
        }
    }
    
    // MARK: - Selected Line Width
    @Published var selectedLineWidth: CGFloat {
        didSet {
            defaults.set(selectedLineWidth, forKey: Keys.selectedLineWidth)
        }
    }
    
    // MARK: - Eraser State
    @Published var isEraserActive: Bool {
        didSet {
            defaults.set(isEraserActive, forKey: Keys.isEraserActive)
        }
    }
    
    // MARK: - Toolbar Visibility
    @Published var showingToolbar: Bool {
        didSet {
            defaults.set(showingToolbar, forKey: Keys.showingToolbar)
        }
    }
    
    // MARK: - Canvas Scale
    @Published var canvasScale: CGFloat {
        didSet {
            defaults.set(canvasScale, forKey: Keys.canvasScale)
        }
    }
    
    // MARK: - Canvas Offset
    @Published var canvasOffset: CGSize {
        didSet {
            defaults.set(canvasOffset.width, forKey: Keys.canvasOffsetWidth)
            defaults.set(canvasOffset.height, forKey: Keys.canvasOffsetHeight)
        }
    }
    
    // MARK: - Last Drawing ID
    var lastDrawingID: String? {
        get {
            defaults.string(forKey: Keys.lastDrawingID)
        }
        set {
            defaults.set(newValue, forKey: Keys.lastDrawingID)
        }
    }
    
    // MARK: - Initialization
    init() {
        // Load saved color or default to black
        self.selectedColor = UserSettings.loadColor() ?? .black
        
        // Load saved line width or default to 5.0
        let savedLineWidth = defaults.double(forKey: Keys.selectedLineWidth)
        self.selectedLineWidth = savedLineWidth > 0 ? CGFloat(savedLineWidth) : 5.0
        
        // Load eraser state or default to false
        self.isEraserActive = defaults.bool(forKey: Keys.isEraserActive)
        
        // Load toolbar visibility or default to true
        if defaults.object(forKey: Keys.showingToolbar) == nil {
            self.showingToolbar = true
        } else {
            self.showingToolbar = defaults.bool(forKey: Keys.showingToolbar)
        }
        
        // Load canvas scale or default to 1.0
        let savedScale = defaults.double(forKey: Keys.canvasScale)
        self.canvasScale = savedScale > 0 ? CGFloat(savedScale) : 1.0
        
        // Load canvas offset or default to zero
        let savedWidth = defaults.double(forKey: Keys.canvasOffsetWidth)
        let savedHeight = defaults.double(forKey: Keys.canvasOffsetHeight)
        self.canvasOffset = CGSize(width: savedWidth, height: savedHeight)
    }
    
    // MARK: - Save Color
    private func saveColor(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        defaults.set(Double(red), forKey: Keys.selectedColorRed)
        defaults.set(Double(green), forKey: Keys.selectedColorGreen)
        defaults.set(Double(blue), forKey: Keys.selectedColorBlue)
        defaults.set(Double(alpha), forKey: Keys.selectedColorAlpha)
    }
    
    // MARK: - Load Color
    private static func loadColor() -> Color? {
        let defaults = UserDefaults.standard
        
        guard defaults.object(forKey: Keys.selectedColorRed) != nil else {
            return nil
        }
        
        let red = defaults.double(forKey: Keys.selectedColorRed)
        let green = defaults.double(forKey: Keys.selectedColorGreen)
        let blue = defaults.double(forKey: Keys.selectedColorBlue)
        let alpha = defaults.double(forKey: Keys.selectedColorAlpha)
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // MARK: - Reset to Defaults
    func resetToDefaults() {
        selectedColor = .black
        selectedLineWidth = 5.0
        isEraserActive = false
        showingToolbar = true
        canvasScale = 1.0
        canvasOffset = .zero
        lastDrawingID = nil
    }
}

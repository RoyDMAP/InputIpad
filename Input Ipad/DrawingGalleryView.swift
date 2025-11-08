//
//  DrawingGalleryView.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/8/25.
//
//

import SwiftUI
import CoreData

struct DrawingGalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var drawings: [NSManagedObject] = []
    @State private var selectedDrawingID: NSManagedObjectID?
    @State private var showingNewDrawing = false
    @State private var coreDataStatus: String = "Checking..."
    @State private var coreDataWorking: Bool = false
    
    // Adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if !coreDataWorking {
                    diagnosticView
                } else if drawings.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(drawings, id: \.objectID) { drawing in
                            DrawingThumbnailView(drawing: drawing)
                                .onTapGesture {
                                    selectedDrawingID = drawing.objectID
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteDrawing(drawing)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Drawings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewDrawing = true }) {
                        Label("New Drawing", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .disabled(!coreDataWorking)
                }
            }
            .onAppear {
                checkCoreDataSetup()
            }
            .fullScreenCover(isPresented: $showingNewDrawing, onDismiss: {
                loadDrawings()
            }) {
                if coreDataWorking {
                    DrawingEditorView()
                } else {
                    Text("Core Data not set up")
                }
            }
            .fullScreenCover(item: Binding(
                get: { selectedDrawingID.map { DrawingIDWrapper(id: $0) } },
                set: { selectedDrawingID = $0?.id }
            )) { wrapper in
                DrawingEditorView(drawingID: wrapper.id)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // DIAGNOSTIC VIEW
    private var diagnosticView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Core Data Setup Issue")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(coreDataStatus)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Fix:")
                    .font(.headline)
                
                Text("1. Go to File → New → File...")
                Text("2. Choose 'Data Model' under Core Data")
                Text("3. Name it: DrawingModel")
                Text("4. Click the + to add an entity")
                Text("5. Name the entity: Drawing")
                Text("6. Add these attributes:")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("   • id (UUID)")
                    Text("   • title (String)")
                    Text("   • drawingData (Binary Data)")
                    Text("   • createdDate (Date)")
                    Text("   • modifiedDate (Date)")
                    Text("   • thumbnail (Binary Data, Optional)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("7. Save and rebuild")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button(action: checkCoreDataSetup) {
                Label("Check Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Drawings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to create your first drawing")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingNewDrawing = true }) {
                Label("Create New Drawing", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Check if Core Data is set up correctly
    private func checkCoreDataSetup() {
        print("🔍 Checking Core Data setup...")
        
        // Check if we can get the persistent store coordinator
        guard let coordinator = viewContext.persistentStoreCoordinator else {
            coreDataStatus = "❌ No persistent store coordinator found"
            coreDataWorking = false
            print(coreDataStatus)
            return
        }
        
        // Check if model is loaded
        let model = coordinator.managedObjectModel
        let entities = model.entities
        
        print("📦 Found \(entities.count) entities in model:")
        for entity in entities {
            print("   • \(entity.name ?? "unnamed")")
        }
        
        // Check if Drawing entity exists
        if let drawingEntity = entities.first(where: { $0.name == "Drawing" }) {
            print("✅ Found 'Drawing' entity")
            
            let attributes = drawingEntity.attributesByName.keys.sorted()
            print("📝 Attributes: \(attributes.joined(separator: ", "))")
            
            coreDataStatus = "✅ Core Data is set up correctly!\n\nEntity: Drawing\nAttributes: \(attributes.count)"
            coreDataWorking = true
            
            // Try to load drawings
            loadDrawings()
        } else {
            print("❌ 'Drawing' entity NOT found")
            
            if entities.isEmpty {
                coreDataStatus = "❌ No entities found in Core Data model.\n\nYou need to create DrawingModel.xcdatamodeld file."
            } else {
                let entityNames = entities.compactMap { $0.name }.joined(separator: ", ")
                coreDataStatus = "❌ 'Drawing' entity not found.\n\nFound entities: \(entityNames)\n\nMake sure the entity is named exactly 'Drawing' (capital D)"
            }
            coreDataWorking = false
        }
    }
    
    // Load drawings safely
    private func loadDrawings() {
        guard coreDataWorking else {
            print("⚠️ Skipping loadDrawings - Core Data not working")
            return
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Drawing")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        
        do {
            drawings = try viewContext.fetch(fetchRequest)
            print("✅ Successfully loaded \(drawings.count) drawings")
        } catch {
            print("❌ Error loading drawings: \(error.localizedDescription)")
            drawings = []
        }
    }
    
    private func deleteDrawing(_ drawing: NSManagedObject) {
        withAnimation {
            viewContext.delete(drawing)
            
            do {
                try viewContext.save()
                loadDrawings()
                print("✅ Drawing deleted successfully")
            } catch {
                print("❌ Error deleting drawing: \(error.localizedDescription)")
            }
        }
    }
}

struct DrawingIDWrapper: Identifiable {
    let id: NSManagedObjectID
}

struct DrawingThumbnailView: View {
    let drawing: NSManagedObject
    
    var thumbnailImage: UIImage? {
        guard let thumbnailData = drawing.value(forKey: "thumbnail") as? Data else { return nil }
        return UIImage(data: thumbnailData)
    }
    
    var title: String {
        drawing.value(forKey: "title") as? String ?? "Untitled"
    }
    
    var modifiedDate: Date {
        drawing.value(forKey: "modifiedDate") as? Date ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 5)
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(modifiedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct DrawingGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingGalleryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

//
//  PersistenceController.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/06/25.
//
//

import CoreData
import PencilKit

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DrawingModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save Drawing
    func saveDrawing(_ drawing: PKDrawing, title: String = "Untitled") {
        let context = container.viewContext
        
        // Create new Drawing entity using NSEntityDescription
        guard let entity = NSEntityDescription.entity(forEntityName: "Drawing", in: context) else {
            print("Failed to find Drawing entity")
            return
        }
        
        let newDrawing = NSManagedObject(entity: entity, insertInto: context)
        
        // Set values using KVC
        newDrawing.setValue(UUID(), forKey: "id")
        newDrawing.setValue(title, forKey: "title")
        newDrawing.setValue(drawing.dataRepresentation(), forKey: "drawingData")
        newDrawing.setValue(Date(), forKey: "createdDate")
        newDrawing.setValue(Date(), forKey: "modifiedDate")
        
        // Generate thumbnail
        if let thumbnail = generateThumbnail(from: drawing) {
            newDrawing.setValue(thumbnail, forKey: "thumbnail")
        }
        
        do {
            try context.save()
            print("Drawing saved successfully!")
        } catch {
            print("Failed to save drawing: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Existing Drawing
    func updateDrawing(_ drawingEntity: NSManagedObject, with newDrawing: PKDrawing) {
        let context = container.viewContext
        
        drawingEntity.setValue(newDrawing.dataRepresentation(), forKey: "drawingData")
        drawingEntity.setValue(Date(), forKey: "modifiedDate")
        
        // Update thumbnail
        if let thumbnail = generateThumbnail(from: newDrawing) {
            drawingEntity.setValue(thumbnail, forKey: "thumbnail")
        }
        
        do {
            try context.save()
            print("Drawing updated successfully!")
        } catch {
            print("Failed to update drawing: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load Drawing
    func loadDrawing(from drawingEntity: NSManagedObject) -> PKDrawing? {
        guard let drawingData = drawingEntity.value(forKey: "drawingData") as? Data else {
            print("No drawing data found")
            return nil
        }
        
        do {
            return try PKDrawing(data: drawingData)
        } catch {
            print("Failed to load drawing: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Delete Drawing
    func deleteDrawing(_ drawing: NSManagedObject) {
        let context = container.viewContext
        context.delete(drawing)
        
        do {
            try context.save()
            print("Drawing deleted successfully!")
        } catch {
            print("Failed to delete drawing: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch All Drawings
    func fetchAllDrawings() -> [NSManagedObject] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Drawing")
        
        // Sort by modified date, most recent first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch drawings: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Generate Thumbnail
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

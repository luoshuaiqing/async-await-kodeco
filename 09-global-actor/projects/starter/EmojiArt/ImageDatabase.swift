
import UIKit

@globalActor actor ImageDatabase {
  static let shared = ImageDatabase()
  
  let imageLoader = ImageLoader()
  
  private var storage: DiskStorage!
  private var storedImageIndex = Set<String>()
  
  func setup() async throws {
    storage = await DiskStorage()
    for fileURL in try await storage.persistedFiles() {
      storedImageIndex.insert(fileURL.lastPathComponent)
    }
  }
  
  func store(image: UIImage, forKey key: String) async throws {
    guard let data = image.pngData() else {
      throw "Could not save image \(key)"
    }
    let fileName = DiskStorage.fileName(for: key)
    try await storage.write(data, name: fileName)
    storedImageIndex.insert(fileName)
  }
  
  func image(_ key: String) async throws -> UIImage {
    let keys = await imageLoader.cache.keys
    if keys.contains(key) {
      print("Cached in-memory")
      return try await imageLoader.image(key)
    }
    
    do {
      let fileName = DiskStorage.fileName(for: key)
      if !storedImageIndex.contains(fileName) {
        throw "Image not persisted"
      }
      
      let data = try await storage.read(name: fileName)
      guard let image = UIImage(data: data) else {
        throw "Invalid image data"
      }
      
      print("Cached on disk")
      
      await imageLoader.add(image, forKey: key)
      return image
    } catch {
      let image = try await imageLoader.image(key)
      try await store(image: image, forKey: key)
      return image
    }
  }
  
  func clear() async {
    for name in storedImageIndex {
      try? await storage.remove(name: name)
    }
    storedImageIndex.removeAll()
  }
  
}

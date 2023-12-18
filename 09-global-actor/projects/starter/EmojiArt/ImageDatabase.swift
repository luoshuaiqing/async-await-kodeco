
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
  
}

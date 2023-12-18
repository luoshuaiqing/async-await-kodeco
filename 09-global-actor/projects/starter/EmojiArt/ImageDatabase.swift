
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
  
}

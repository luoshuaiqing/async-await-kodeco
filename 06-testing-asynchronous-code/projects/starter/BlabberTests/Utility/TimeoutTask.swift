//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by Shuaiqing Luo on 12/10/23.
//

import Foundation

class TimeoutTask<Success> {
  typealias OperationHandler = @Sendable () async throws -> Success
  let nanoseconds: UInt64
  let operation: OperationHandler
  
  private var continuation: CheckedContinuation<Success, Error>?
  var value: Success {
    get // define the getter
    async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        
        Task {
          try await Task.sleep(nanoseconds:nanoseconds)
          self.continuation?.resume(throwing: TimeoutError())
          self.continuation = nil
        }
        
        Task {
          let result = try await operation()
          self.continuation?.resume(returning: result)
          self.continuation = nil
        }
      }
    }
  }
  
  init(seconds: TimeInterval, operation: @escaping OperationHandler) {
    self.nanoseconds = UInt64(seconds * 1_000_000_000)
    self.operation = operation
  }
}

extension TimeoutTask {
  struct TimeoutError: LocalizedError {
    var errorDescription: String? {
      return "The operation timed out."
    }
  }
  
  func cancel() {
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}

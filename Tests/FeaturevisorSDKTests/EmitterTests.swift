import XCTest

@testable import FeaturevisorSDK

final class EmitterTests: XCTestCase {
  
  func testEmitterInvokeListener() {
    
    let emitter = Emitter()
    var isListenerCalled: Bool = false
    
    
    emitter.addListener(.activation) { _ in
      isListenerCalled = true
    }
    
    emitter.emit(.activation, ["test", 1, true])
    
    XCTAssertTrue(isListenerCalled)
  }
  
  func testEmitterNotInvokeRemovedListener() {
    
    let emitter = Emitter()
    var isListenerCalled: Bool = false
    
    
    emitter.addListener(.activation) { _ in
      isListenerCalled = true
    }
    
    emitter.removeAllListeners(.activation)
    
    emitter.emit(.activation, ["test", 1, true])
    
    XCTAssertFalse(isListenerCalled)
  }
  
  func testEmitterPassParamsToListener() {
    let emitter = Emitter()
    var params: [Any] = []
    
    emitter.addListener(.activation) { receivedParams in
      params = receivedParams
    }
    
    emitter.emit(.activation, ["test", 1, true])
    
    XCTAssertEqual(params.count, 3)
    XCTAssertEqual(params[0] as? String, "test")
    XCTAssertEqual(params[1] as? Int, 1)
    XCTAssertEqual(params[2] as? Bool, true)
  }

}


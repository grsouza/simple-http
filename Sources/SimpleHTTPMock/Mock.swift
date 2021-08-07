import Foundation
import SimpleHTTP
import XCTestDynamicOverlay

extension HTTPClient {

  public static var noop: HTTPClient {
    HTTPClient(request: { _, _ in })
  }

  public static var failing: HTTPClient {
    HTTPClient(request: { _, _ in XCTFail("HTTPClient.request(_:_:) is not implemented.") })
  }
}

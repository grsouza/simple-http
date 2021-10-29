import Foundation
import XCTestDynamicOverlay

#if DEBUG
  extension HTTPURLResponse {
    static let noop = HTTPURLResponse(
      url: URL(string: "https://grds.dev")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    static let failing = HTTPURLResponse(
      url: URL(string: "https://grds.dev")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
  }

  extension Response {
    static var noop: Response {
      let endpoint = Endpoint(path: "", method: .get)
      let request = try! endpoint.urlRequest(with: URL(string: "https://grds.dev")!)
      return Response(endpoint: endpoint, request: request, response: .noop, data: Data())
    }

    static var failing: Response {
      let endpoint = Endpoint(path: "", method: .get)
      let request = try! endpoint.urlRequest(with: URL(string: "https://grds.dev")!)
      return Response(endpoint: endpoint, request: request, response: .failing, data: Data())
    }
  }

  extension HTTPClient {
    public static var noop: HTTPClient {
      HTTPClient { _ in .noop }
    }

    public static var failing: HTTPClient {
      HTTPClient { _ in
        XCTFail("HTTPClient.request(_:) is not implemented")
        return .failing
      }
    }
  }
#endif

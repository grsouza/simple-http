import Foundation
import XCTestDynamicOverlay

#if DEBUG
  extension HTTPURLResponse {
    static let noop = HTTPURLResponse(
      url: URL(string: "https://grds.dev")!, statusCode: 200, httpVersion: nil, headerFields: nil
    )!
    static let failing = HTTPURLResponse(
      url: URL(string: "https://grds.dev")!, statusCode: 500, httpVersion: nil, headerFields: nil
    )!
  }

  extension Response {
    static var noop: Response {
      get async {
        let endpoint = Endpoint(path: "", method: .get)
        let request = try! await endpoint.urlRequest(
          with: URL(string: "https://grds.dev")!, in: HTTPClient.noop)
        return Response(endpoint: endpoint, request: request, response: .noop, data: Data())
      }
    }

    static var failing: Response {
      get async {
        let endpoint = Endpoint(path: "", method: .get)
        let request = try! await endpoint.urlRequest(
          with: URL(string: "https://grds.dev")!, in: HTTPClient.failing)
        return Response(endpoint: endpoint, request: request, response: .failing, data: Data())
      }
    }
  }

  extension HTTPClient {
    public static var noop: HTTPClientProtocol {
      HTTPClientMock { _ in await .noop }
    }

    public static var failing: HTTPClientProtocol {
      HTTPClientMock { _ in
        XCTFail("HTTPClient.request(_:) is not implemented")
        return await .failing
      }
    }
  }

  public final class HTTPClientMock: HTTPClientProtocol {

    public var requestHandler: (_ endpoint: Endpoint) async throws -> Response

    public init(requestHandler: @escaping (_ endpoint: Endpoint) async throws -> Response) {
      self.requestHandler = requestHandler
    }

    public func request(_ endpoint: Endpoint) async throws -> Response {
      try await requestHandler(endpoint)
    }
  }
#endif

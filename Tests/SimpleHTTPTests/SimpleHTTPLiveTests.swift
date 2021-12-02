import XCTest

@testable import SimpleHTTP

final class SimpleHTTPLiveTests: XCTestCase {
  let url = URL(string: "https://example.com")!

  override func setUp() {
    Current = .failing
  }

  func testRequest() async throws {
    let body = """
      {
        "email": "johndoe@gmail.com",
        "password": "the.pass"
      }
      """.data(using: .utf8)!

    var lastAdapterExecuted = 0
    var lastInterceptorExecuted = 0

    let client = HTTPClient(
      baseURL: url,
      adapters: (1..<6).map { i in
        RequestAdapterMock { _, request in
          XCTAssertEqual(lastAdapterExecuted, i - 1)
          lastAdapterExecuted = i

          try await Task.sleep(nanoseconds: UInt64.random(in: 0..<2000))
          return request
        }
      },
      interceptors: (1..<6).map { i in
        ResponseInterceptorMock { _, response in
          XCTAssertEqual(lastInterceptorExecuted, i - 1)
          lastInterceptorExecuted = i

          try await Task.sleep(nanoseconds: UInt64.random(in: 0..<2000))
          return try response.get()
        }
      }
    )

    Current.session.request = { _ in
      (
        Data(),
        HTTPURLResponse(
          url: URL(string: "https://example.com/auth/signup?type=password&scope=admin")!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
      )
    }

    _ = try await client.request(
      Endpoint(
        path: "/auth/signup",
        method: .post,
        query: [
          URLQueryItem(name: "type", value: "password"),
          URLQueryItem(name: "scope", value: "admin"),
        ],
        headers: ["Content-Type": "application/json"],
        body: body
      )
    )

    XCTAssertEqual(lastAdapterExecuted, 5)
    XCTAssertEqual(lastInterceptorExecuted, 5)
  }
}

struct RequestAdapterMock: RequestAdapter {
  let handler: (_ client: HTTPClient, _ request: URLRequest) async throws -> URLRequest

  func adapt(_ client: HTTPClient, _ request: URLRequest) async throws -> URLRequest {
    try await handler(client, request)
  }
}

struct ResponseInterceptorMock: ResponseInterceptor {
  let handler: (_ client: HTTPClient, _ result: Result<Response, Error>) async throws -> Response

  func intercept(_ client: HTTPClient, _ result: Result<Response, Error>) async throws -> Response {
    try await handler(client, result)
  }
}

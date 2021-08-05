import XCTest

@testable import SimpleHTTP

final class SimpleHTTPTests: XCTestCase {

  let url = URL(string: "https://example.com")!

  override func setUp() {
    Current = .failing
  }

  func testEndpointUrlRequest() throws {
    let body = """
      {
          "email": "johndoe@gmail.com",
          "password": "the.pass"
      }
      """.data(using: .utf8)!
    let endpoint = Endpoint(
      path: "/auth/signup",
      method: .post,
      query: [
        URLQueryItem(name: "type", value: "password"),
        URLQueryItem(name: "scope", value: "admin"),
      ],
      headers: ["Content-Type": "application/json"],
      body: body
    )

    let request = try endpoint.urlRequest(with: url)
    XCTAssertEqual(
      request.url?.absoluteString, "https://example.com/auth/signup?type=password&scope=admin")
    XCTAssertEqual(request.allHTTPHeaderFields, ["Content-Type": "application/json"])
    XCTAssertEqual(request.httpBody, body)
    XCTAssertEqual(request.httpMethod, "POST")
  }

  func testRequest() throws {
    let body = """
      {
          "email": "johndoe@gmail.com",
          "password": "the.pass"
      }
      """.data(using: .utf8)!

    var lastAdapterExecuted = 0
    var lastInterceptorExecuted = 0
    let client = HTTPClient(
      url: url,
      adapters: (1..<6).map { i in
        { request, completion in
          XCTAssertEqual(lastAdapterExecuted, i - 1)
          lastAdapterExecuted = i

          DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0..<2)) {
            completion(.success(request))
          }
        }
      },
      interceptors: (1..<6).map { i in
        { response, completion in
          XCTAssertEqual(lastInterceptorExecuted, i - 1)
          lastInterceptorExecuted = i

          DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0..<2)) {
            completion(.success(response))
          }
        }
      }
    )

    Current.session.request = { _, completion in
      completion(
        Data(),
        HTTPURLResponse(
          url: URL(string: "https://example.com/auth/signup?type=password&scope=admin")!,
          statusCode: 200, httpVersion: nil, headerFields: nil), nil)
    }

    let expectation = self.expectation(description: #function)

    client.request(
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
    ) { result in
      XCTAssertEqual(lastAdapterExecuted, 5)
      XCTAssertEqual(lastInterceptorExecuted, 5)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 20, handler: nil)
  }
}

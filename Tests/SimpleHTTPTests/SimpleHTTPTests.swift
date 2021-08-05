import XCTest

@testable import SimpleHTTP

final class SimpleHTTPTests: XCTestCase {

  let url = URL(string: "https://example.com")!

  func testEndpointUrlRequest() throws {
    let body = try ["email": "johndoe@gmail.com", "password": "the.pass"].encoded()
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
    let body = try ["email": "johndoe@gmail.com", "password": "the.pass"].encoded()

    var lastAdapterExecuted = 0
    let client = HTTPClient(
      url: url,
      adapters: (1..<11).map { i in
        { request, completion in
          XCTAssertEqual(lastAdapterExecuted, i - 1)
          lastAdapterExecuted = i

          DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0..<2)) {
            completion(.success(request))
          }
        }
      }
    )

    Current.request = { _, completion in
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
      dump(result)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 20, handler: nil)
  }
}

extension Encodable {
  func encoded() throws -> Data {
    try JSONEncoder().encode(self)
  }
}

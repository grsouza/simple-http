import XCTest

@testable import SimpleHTTP

final class SimpleHTTPTests: XCTestCase {
    let url = URL(string: "https://example.com")!

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
                URLQueryItem(name: "scope", value: "admin")
            ],
            headers: ["Content-Type": "application/json"],
            body: body
        )

        let request = try endpoint.urlRequest(with: url)
        XCTAssertEqual(
            request.url?.absoluteString, "https://example.com/auth/signup?type=password&scope=admin"
        )
        XCTAssertEqual(request.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.httpMethod, "POST")
    }
}

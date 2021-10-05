@testable import SimpleHTTP
import XCTest

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 15.0.0, *)
@available(macOS 12.0.0, *)
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
        let client = HTTPClient.live(
            url: url,
            adapters: (1..<6).map { i in
                { request in
                    XCTAssertEqual(lastAdapterExecuted, i - 1)
                    lastAdapterExecuted = i

                    await Task.sleep(UInt64.random(in: 0..<2000))
                    return request
                }
            },
            interceptors: (1..<6).map { i in
                { _, response in
                    XCTAssertEqual(lastInterceptorExecuted, i - 1)
                    lastInterceptorExecuted = i

                    await Task.sleep(UInt64.random(in: 0..<2000))
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
#endif

import Foundation

public enum Defaults {
  public static var jsonDecoder = JSONDecoder()
  public static var adapters: [RequestAdapter] = [RequestAdapters.defaultHeaders]
  public static var interceptors: [RequestInterceptor] = []
}

public typealias RequestAdapter = (_ request: URLRequest) async throws -> URLRequest

public typealias RequestInterceptor = (_ client: HTTPClient, _ result: Result<Response, Error>)
  async throws -> Response

public struct HTTPClient {

  public var request: (_ endpoint: Endpoint) async throws -> Response

  public init(
    request: @escaping (_ endpoint: Endpoint) async throws -> Response
  ) {
    self.request = request
  }
}

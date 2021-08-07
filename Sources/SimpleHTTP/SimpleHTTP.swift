import Foundation

public enum Defaults {
  public static var jsonDecoder = JSONDecoder()
  public static var adapters: [RequestAdapter] = []
  public static var interceptors: [RequestInterceptor] = []
}

public typealias RequestAdapter = (
  _ request: URLRequest, _ completion: @escaping (Result<URLRequest, Error>) -> Void
) -> Void

public typealias RequestInterceptor = (
  _ client: HTTPClient, _ result: Result<Response, Error>,
  _ completion: @escaping (Result<Response, Error>) -> Void
) -> Void

public struct HTTPClient {

  public var request:
    (_ endpoint: Endpoint, _ completion: @escaping (Result<Response, Error>) -> Void) -> Void

  public init(
    request: @escaping (
      _ endpoint: Endpoint, _ completion: @escaping (Result<Response, Error>) -> Void
    ) -> Void
  ) {
    self.request = request
  }
}

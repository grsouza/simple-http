import Foundation

public enum Defaults {
  public static var jsonDecoder = JSONDecoder()
  public static var adapters: [RequestAdapter] = [DefaultHeaders()]
  public static var interceptors: [ResponseInterceptor] = [
    StatusCodeValidator(),
    RequestRetrier(),
  ]
}

public protocol RequestAdapter {
  func adapt(_ client: HTTPClientProtocol, _ request: inout URLRequest) async throws
}

public protocol ResponseInterceptor {
  func intercept(_ client: HTTPClientProtocol, _ result: Result<Response, Error>) async throws
    -> Response
}

public protocol HTTPClientProtocol {
  func request(_ endpoint: Endpoint) async throws -> Response
}

public final class HTTPClient: HTTPClientProtocol {
  public let baseURL: URL
  public let adapters: [RequestAdapter]
  public let interceptors: [ResponseInterceptor]

  public init(
    baseURL: URL,
    adapters: [RequestAdapter] = Defaults.adapters,
    interceptors: [ResponseInterceptor] = Defaults.interceptors
  ) {
    self.baseURL = baseURL
    self.adapters = adapters
    self.interceptors = interceptors
  }

  public func request(_ endpoint: Endpoint) async throws -> Response {
    let request = try await buildURLRequest(endpoint, url: baseURL, adapters: adapters)

    do {
      let (data, urlResponse) = try await Current.session.request(request)

      guard let httpResponse = urlResponse as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
      }

      let response = Response(
        endpoint: endpoint, request: request, response: httpResponse, data: data)
      return try await applyInterceptors(
        interceptors,
        result: .success(response)
      )
    } catch {
      return try await applyInterceptors(
        interceptors,
        result: .failure(error)
      )
    }
  }

  private func buildURLRequest(
    _ endpoint: Endpoint,
    url: URL, adapters: [RequestAdapter]
  ) async throws -> URLRequest {
    var request = try await endpoint.urlRequest(with: url, in: self)

    for adapter in adapters {
      try await adapter.adapt(self, &request)
    }

    return request
  }

  private func applyInterceptors(
    _ interceptors: [ResponseInterceptor],
    result: Result<Response, Error>
  ) async throws -> Response {
    var result = result

    for interceptor in interceptors {
      do {
        let response = try await interceptor.intercept(self, result)
        result = .success(response)
      } catch {
        throw error
      }
    }

    return try result.get()
  }

}

public struct APIError: Error {
  public let response: Response
}

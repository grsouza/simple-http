import Foundation

public struct Endpoint {
  public var path: String
  public var method: HTTPMethod
  public var query: [URLQueryItem]?
  public var headers: [String: String]
  public var body: Data?

  public var additionalAdapters: [RequestAdapter]
  public var additionalInterceptors: [ResponseInterceptor]

  public init(
    path: String,
    method: HTTPMethod,
    query: [URLQueryItem]? = nil,
    headers: [String: String] = [:],
    body: Data? = nil,
    additionalAdapters: [RequestAdapter] = [],
    additionalInterceptors: [ResponseInterceptor] = []
  ) {
    self.path = path
    self.method = method
    self.query = query
    self.headers = headers
    self.body = body
    self.additionalAdapters = additionalAdapters
    self.additionalInterceptors = additionalInterceptors
  }

  public func urlRequest(with url: URL) throws -> URLRequest {
    guard
      var components = URLComponents(
        url: url.appendingPathComponent(path), resolvingAgainstBaseURL: true
      )
    else {
      throw URLError(.badURL)
    }

    if let query = query, !query.isEmpty {
      components.queryItems = components.queryItems ?? []
      components.queryItems!.append(contentsOf: query)
    }

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = headers
    request.httpBody = body

    return request
  }
}

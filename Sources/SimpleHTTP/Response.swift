import Foundation

public struct Response {
  public let endpoint: Endpoint
  public let request: URLRequest
  public let response: HTTPURLResponse
  public let data: Data

  public init(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, data: Data) {
    self.endpoint = endpoint
    self.request = request
    self.response = response
    self.data = data
  }

  public var statusCode: Int {
    response.statusCode
  }

  /// Serializes response's data as a JSON object.
  public func json() throws -> Any {
    try JSONSerialization.jsonObject(with: data, options: .allowFragments)
  }

  /// Decodes response's data to a `Decodable` type.
  public func decoded<T: Decodable>(
    to type: T.Type = T.self,
    using decoder: JSONDecoder = Defaults.jsonDecoder
  ) throws -> T {
    try decoder.decode(type, from: data)
  }

  /// Decodes response's data to string representation.
  public func string(encoding: String.Encoding = .utf8) -> String? {
    String(data: data, encoding: encoding)
  }
}

extension Result where Success == Response, Failure == Error {

  public var response: Response? {
    if case .success(let response) = self {
      return response
    }
    return nil
  }

  public var error: Error? {
    if case .failure(let error) = self {
      return error
    }
    return nil
  }

  public func json() -> Result<Any, Failure> {
    flatMap { response in
      Result<Any, Failure> { try response.json() }
    }
  }

  public func decoded<T: Decodable>(
    to type: T.Type = T.self,
    using decoder: JSONDecoder = Defaults.jsonDecoder
  ) -> Result<T, Failure> {
    flatMap { response in
      Result<T, Failure> { try response.decoded(to: type, using: decoder) }
    }
  }

  public func string(encoding: String.Encoding = .utf8) -> Result<String, Failure> {
    flatMap { response in
      guard let string = response.string(encoding: encoding) else {
        return .failure(WrongStringEncoding())
      }

      return .success(string)
    }
  }
}

struct WrongStringEncoding: Error {}

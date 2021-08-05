import Foundation

public struct Response {
  public let request: URLRequest
  public let response: HTTPURLResponse
  public let data: Data

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

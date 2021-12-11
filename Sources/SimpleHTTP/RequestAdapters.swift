import Foundation

public struct DefaultHeaders: RequestAdapter {

  public init() {}

  public func adapt(_ client: HTTPClientProtocol, _ request: inout URLRequest) async throws {
    let acceptEncoding: String = {
      let encodings = ["br", "gzip", "deflate"]
      return encodings.qualityEncoded()
    }()

    let acceptLanguage = Locale.preferredLanguages.prefix(6).qualityEncoded()
    request.setValue(acceptEncoding, forHTTPHeaderField: "Accept-Encoding")
    request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
  }
}

extension Collection where Element == String {
  func qualityEncoded() -> String {
    enumerated().map { index, encoding in
      let quality = 1.0 - (Double(index) * 0.1)
      return "\(encoding);q=\(quality)"
    }.joined(separator: ", ")
  }
}

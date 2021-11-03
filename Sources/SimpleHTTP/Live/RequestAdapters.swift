import Foundation

public enum RequestAdapters {
  public static var defaultHeaders: RequestAdapter {
    { request in
      let acceptEncoding: String = {
        let encodings = ["br", "gzip", "deflate"]
        return encodings.qualityEncoded()
      }()

      let acceptLanguage = Locale.preferredLanguages.prefix(6).qualityEncoded()

      var request = request
      request.setValue(acceptEncoding, forHTTPHeaderField: "Accept-Encoding")
      request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
      return request
    }
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

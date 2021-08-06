import Foundation

public enum RequestAdapters {
  public static var defaultHeaders: RequestAdapter {
    { request, completion in
      let acceptEncoding: String = {
        let encodings: [String]

        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
          encodings = ["br", "gzip", "deflate"]
        } else {
          encodings = ["gzip", "deflate"]
        }

        return encodings.qualityEncoded()
      }()

      let acceptLanguage = Locale.preferredLanguages.prefix(6).qualityEncoded()

      var request = request
      request.setValue(acceptEncoding, forHTTPHeaderField: "Accept-Encoding")
      request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
      completion(.success(request))
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

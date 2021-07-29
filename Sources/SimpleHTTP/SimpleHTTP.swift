import Foundation

#if canImport(Combine)
  import Combine
#endif

public enum HTTPMethod: String {
  case get = "GET"
  case head = "HEAD"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case connect = "CONNECT"
  case options = "OPTIONS"
  case trace = "TRACE"
  case patch = "PATCH"
}

public struct Response {
  public let request: URLRequest
  public let response: HTTPURLResponse
  public let data: Data

  public var statusCode: Int {
    response.statusCode
  }

  public func json() throws -> Any {
    try JSONSerialization.jsonObject(with: data, options: .allowFragments)
  }

  public func decoding<T: Decodable>(
    to type: T.Type = T.self,
    using decoder: JSONDecoder = JSONDecoder()
  ) throws -> T {
    try decoder.decode(type, from: data)
  }

  public func string(encoding: String.Encoding = .utf8) -> String? {
    String(data: data, encoding: encoding)
  }
}

public final class HTTPClient {

  public let url: URL
  public let session: URLSession

  public init(url: URL, session: URLSession = .shared) {
    self.url = url
    self.session = session
  }

  public func request(
    _ endpoint: Endpoint,
    completionHandler: @escaping (Result<Response, Error>) -> Void
  ) {
    let urlRequest: URLRequest
    do {
      urlRequest = try endpoint.urlRequest(with: url)
    } catch {
      return completionHandler(.failure(error))
    }

    session.dataTask(with: urlRequest) { data, response, error in
      if let error = error {
        return completionHandler(.failure(error))
      }

      guard let response = response as? HTTPURLResponse, let data = data else {
        return completionHandler(.failure(URLError(.badServerResponse)))
      }

      completionHandler(.success(Response(request: urlRequest, response: response, data: data)))
    }
    .resume()
  }

  @available(macOS 10.15, *)
  public func requestPublisher(_ endpoint: Endpoint) -> AnyPublisher<
    Response, Error
  > {
    let urlRequest: URLRequest
    do {
      urlRequest = try endpoint.urlRequest(with: url)
    } catch {
      return Fail(error: error).eraseToAnyPublisher()
    }

    return session.dataTaskPublisher(for: urlRequest)
      .mapError { $0 as Error }
      .tryMap { (data, response) throws -> (data: Data, response: HTTPURLResponse) in
        guard let response = response as? HTTPURLResponse else {
          throw URLError(.badServerResponse)
        }

        return (data: data, response: response)
      }
      .map { data, response in
        Response(request: urlRequest, response: response, data: data)
      }
      .eraseToAnyPublisher()
  }
}

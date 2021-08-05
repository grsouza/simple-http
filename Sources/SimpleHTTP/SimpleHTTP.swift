import Foundation
import os

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

public enum Defaults {
  public static var jsonDecoder = JSONDecoder()
  public static var urlSession = URLSession.shared
  public static var adapters: [RequestAdapter] = []
  public static var interceptors: [ResponseInterceptor] = []
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
    using decoder: JSONDecoder = Defaults.jsonDecoder
  ) throws -> T {
    try decoder.decode(type, from: data)
  }

  public func string(encoding: String.Encoding = .utf8) -> String? {
    String(data: data, encoding: encoding)
  }
}

public typealias RequestAdapter = (
  _ request: URLRequest, _ completion: @escaping (Result<URLRequest, Error>) -> Void
) -> Void
public typealias ResponseInterceptor = (
  _ response: Response, _ completion: @escaping (Result<Response, Error>) -> Void
) -> Void

public protocol URLSessionProtocol {
  func dataTask(
    with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> URLSessionDataTask

  @available(macOS 10.15, *)
  func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
}

struct World {
  var request: (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> Void
}

#if DEBUG
  var Current = World(request: { request, completion in
    URLSession.shared
      .dataTask(with: request, completionHandler: completion)
      .resume()
  })
#else
  let Current = World(request: { request, completion in
    URLSession.shared
      .dataTask(with: request, completionHandler: completion)
      .resume()
  })
#endif

extension URLSession: URLSessionProtocol {}

public final class HTTPClient {

  public let url: URL

  private let adapters: [RequestAdapter]
  private let interceptors: [ResponseInterceptor]

  public init(
    url: URL,
    adapters: [RequestAdapter] = Defaults.adapters,
    interceptors: [ResponseInterceptor] = Defaults.interceptors
  ) {
    self.url = url
    self.adapters = adapters
    self.interceptors = interceptors
  }

  public func request(
    _ endpoint: Endpoint,
    completionHandler: @escaping (Result<Response, Error>) -> Void
  ) {
    var urlRequest: URLRequest
    do {
      urlRequest = try buildURLRequest(endpoint)
    } catch {
      return completionHandler(.failure(error))
    }

    Current.request(urlRequest) { [weak self] data, response, error in
      guard let self = self else { return }

      if let error = error {
        return completionHandler(.failure(error))
      }

      guard let httpResponse = response as? HTTPURLResponse, let data = data else {
        return completionHandler(.failure(URLError(.badServerResponse)))
      }

      var response = Response(request: urlRequest, response: httpResponse, data: data)
      var error: Error?

      let semaphore = DispatchSemaphore(value: 0)

      for interceptor in self.interceptors {
        interceptor(response) { result in
          switch result {
          case .success(let newResponse):
            response = newResponse
          case .failure(let err):
            error = err
          }

          semaphore.signal()
        }

        semaphore.wait()

        if let error = error {
          return completionHandler(.failure(error))
        }
      }

      completionHandler(.success(response))
    }
  }

  //  @available(macOS 10.15, *)
  //  public func requestPublisher(_ endpoint: Endpoint) -> AnyPublisher<
  //    Response, Error
  //  > {
  //    let urlRequest: URLRequest
  //    do {
  //      urlRequest = try buildURLRequest(endpoint)
  //    } catch {
  //      return Fail(error: error).eraseToAnyPublisher()
  //    }
  //
  //    return session.dataTaskPublisher(for: urlRequest)
  //      .mapError { $0 as Error }
  //      .tryMap { (data, response) throws -> (data: Data, response: HTTPURLResponse) in
  //        guard let response = response as? HTTPURLResponse else {
  //          throw URLError(.badServerResponse)
  //        }
  //
  //        return (data: data, response: response)
  //      }
  //      .map { data, response in
  //        Response(request: urlRequest, response: response, data: data)
  //      }
  //      .eraseToAnyPublisher()
  //  }

  private func buildURLRequest(_ endpoint: Endpoint) throws -> URLRequest {
    var urlRequest = try endpoint.urlRequest(with: url)
    var error: Error?
    let semaphore = DispatchSemaphore(value: 0)

    for adapter in adapters {
      adapter(urlRequest) { result in
        switch result {
        case .success(let newRequest):
          urlRequest = newRequest
        case .failure(let err):
          error = err
        }

        semaphore.signal()
      }

      semaphore.wait()

      if let error = error {
        throw error
      }
    }

    return urlRequest
  }
}

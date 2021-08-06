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

public final class HTTPClient {

  public let url: URL

  private let adapters: [RequestAdapter]
  private let interceptors: [RequestInterceptor]

  public init(
    url: URL,
    adapters: [RequestAdapter] = Defaults.adapters,
    interceptors: [RequestInterceptor] = Defaults.interceptors
  ) {
    self.url = url
    self.adapters = [RequestAdapters.defaultHeaders] + adapters
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

    Current.session.request(urlRequest) { [weak self] data, response, error in
      guard let self = self else { return }

      if let error = error {
        return self.applyInterceptors(.failure(error), completion: completionHandler)
      }

      guard let httpResponse = response as? HTTPURLResponse, let data = data else {
        return self.applyInterceptors(
          .failure(URLError(.badServerResponse)), completion: completionHandler)
      }

      let response = Response(
        endpoint: endpoint, request: urlRequest, response: httpResponse, data: data)
      self.applyInterceptors(.success(response), completion: completionHandler)
    }
  }

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

  private func applyInterceptors(
    _ result: Result<Response, Error>,
    completion: @escaping (Result<Response, Error>) -> Void
  ) {
    let semaphore = DispatchSemaphore(value: 0)
    var result = result

    for interceptor in interceptors {
      interceptor(self, result) { newResult in
        result = newResult

        semaphore.signal()
      }

      semaphore.wait()

      if case .failure = result {
        return completion(result)
      }
    }

    completion(result)
  }
}

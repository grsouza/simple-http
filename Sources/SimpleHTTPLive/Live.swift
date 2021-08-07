import Foundation
import SimpleHTTP

extension HTTPClient {
  public static func live(
    url: URL,
    adapters: [RequestAdapter] = Defaults.adapters,
    interceptors: [RequestInterceptor] = Defaults.interceptors
  ) -> HTTPClient {
    return HTTPClient(
      request: { endpoint, completion in
        var urlRequest: URLRequest
        do {
          urlRequest = try buildURLRequest(endpoint, url: url, adapters: adapters)
        } catch {
          return completion(.failure(error))
        }

        Current.session.request(urlRequest) { data, response, error in
          if let error = error {
            return applyInterceptors(
              interceptors, client: .live(url: url, adapters: adapters, interceptors: interceptors),
              result: .failure(error), completion: completion)
          }

          guard let httpResponse = response as? HTTPURLResponse, let data = data else {
            return applyInterceptors(
              interceptors, client: .live(url: url, adapters: adapters, interceptors: interceptors),
              result: .failure(URLError(.badServerResponse)), completion: completion)
          }

          let response = Response(
            endpoint: endpoint, request: urlRequest, response: httpResponse, data: data)
          applyInterceptors(
            interceptors, client: .live(url: url, adapters: adapters, interceptors: interceptors),
            result: .success(response), completion: completion)
        }
      }
    )
  }
}

private func buildURLRequest(_ endpoint: Endpoint, url: URL, adapters: [RequestAdapter]) throws
  -> URLRequest
{
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
  _ interceptors: [RequestInterceptor],
  client: HTTPClient,
  result: Result<Response, Error>,
  completion: @escaping (Result<Response, Error>) -> Void
) {
  let semaphore = DispatchSemaphore(value: 0)
  var result = result

  for interceptor in interceptors {
    interceptor(client, result) { newResult in
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

import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)
  @available(iOS 15.0.0, *)
  @available(macOS 12.0.0, *)
  extension HTTPClient {
    public static func live(
      url: URL,
      adapters: [RequestAdapter] = Defaults.adapters,
      interceptors: [RequestInterceptor] = Defaults.interceptors
    ) -> HTTPClient {
      HTTPClient(
        request: { endpoint in
          let request = try await buildURLRequest(endpoint, url: url, adapters: adapters)

          do {
            let (data, response) = try await Current.session.request(request)

            guard let httpRespnse = response as? HTTPURLResponse else {
              return try await applyInterceptors(
                interceptors,
                client: .live(url: url, adapters: adapters, interceptors: interceptors),
                result: .failure(URLError(.badServerResponse))
              )
            }

            return try await applyInterceptors(
              interceptors,
              client: .live(url: url, adapters: adapters, interceptors: interceptors),
              result: .success(
                Response(endpoint: endpoint, request: request, response: httpRespnse, data: data))
            )
          } catch {
            return try await applyInterceptors(
              interceptors,
              client: .live(url: url, adapters: adapters, interceptors: interceptors),
              result: .failure(error)
            )
          }
        }
      )
    }
  }

  @available(iOS 15.0.0, *)
  @available(macOS 12.0.0, *)
  private func buildURLRequest(
    _ endpoint: Endpoint,
    url: URL, adapters: [RequestAdapter]
  ) async throws -> URLRequest {
    var urlRequest = try endpoint.urlRequest(with: url)

    for adapter in adapters {
      urlRequest = try await adapter(urlRequest)
    }

    return urlRequest
  }

  @available(iOS 15.0.0, *)
  @available(macOS 12.0.0, *)
  private func applyInterceptors(
    _ interceptors: [RequestInterceptor],
    client: HTTPClient,
    result: Result<Response, Error>
  ) async throws -> Response {
    var result = result

    for interceptor in interceptors {
      do {
        let response = try await interceptor(client, result)
        result = .success(response)
      } catch {
        throw error
      }
    }

    return try result.get()
  }
#endif

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

public final class HTTPClient {

    public let url: URL
    public let session: URLSession

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func request(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<(data: Data, response: URLResponse), Error>) -> Void
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

            guard let response = response, let data = data else {
                return completionHandler(.failure(URLError(.badServerResponse)))
            }

            completionHandler(.success((data, response)))
        }
        .resume()
    }

    @available(macOS 10.15, *)
    public func requestPublisher(_ endpoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest(with: url)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: urlRequest).mapError { $0 as Error }.eraseToAnyPublisher()
    }
}

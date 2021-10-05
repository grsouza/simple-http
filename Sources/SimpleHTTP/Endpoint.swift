import Foundation

public struct Endpoint: Hashable {
    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]?
    public let headers: [String: String]
    public let body: Data?
    
    public init(
        path: String,
        method: HTTPMethod,
        query: [URLQueryItem]? = nil,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
    }
    
    public func urlRequest(with url: URL) throws -> URLRequest {
        guard
            var components = URLComponents(
                url: url.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        else {
            throw URLError(.badURL)
        }
        
        if let query = query, !query.isEmpty {
            components.queryItems = components.queryItems ?? []
            components.queryItems!.append(contentsOf: query)
        }
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        return request
    }
}

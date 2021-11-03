import Foundation
import XCTestDynamicOverlay

struct World {
    var session: Session

    struct Session {
        var request: (URLRequest) async throws -> (Data, URLResponse)
    }
}

extension World {
    static var live: World {
        World(
            session: Session(
                request: { request in
                    if #available(iOS 15.0, macOS 12, *) {
                        return try await URLSession.shared.data(for: request)
                    } else {
                        return try await withCheckedThrowingContinuation { continuation in
                            let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
                                if let error = error {
                                    continuation.resume(throwing: error)
                                    return
                                }

                                guard let data = data, let response = response else {
                                    continuation.resume(throwing: URLError(.badServerResponse))
                                    return
                                }

                                continuation.resume(returning: (data, response))
                            }

                            dataTask.resume()
                        }
                    }
                }
            )
        )
    }

#if DEBUG
    /// A World implementation that does nothing when called.
    /// Used for testing purpose only.
    static var noop: Self {
        Self(
            session: Session(
                request: { _ in
                    return (Data(), HTTPURLResponse.noop)
                }
            )
        )
    }

    /// A World implementation that always fails when called.
    /// Used for testing purpose only.
    static var failing: Self {
        Self(
            session: Session(
                request: { _ in
                    XCTFail("Session.request(_:completion:) is not implemented!")
                    return (Data(), HTTPURLResponse.failing)
                }
            )
        )
    }
#endif
}

#if DEBUG
var Current = World.live
#else
let Current = World.live
#endif

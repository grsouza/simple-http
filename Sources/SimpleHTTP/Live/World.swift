import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)

struct World {
    var session: Session
    
    struct Session {
        var request: (URLRequest) async throws -> (Data, URLResponse)
    }
}

extension World {
    @available(iOS 15.0, *)
    static var live: Self {
        Self(
            session: Session(
                request: { request in
                    try await URLSession.shared.data(for: request)
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
                request: { _ in fatalError() }
            )
        )
    }
    
    /// A World implementation that always fails when called.
    /// Used for testing purpose only.
    static var failing: Self {
        Self(
            session: Session(
                request: { _ in
                    // TODO: instead of crashing, use pointfree's xctest-dynamic-overlay package.
                    fatalError("Session.request(_:completion:) is not implemented!")
                }
            )
        )
    }
#endif
}

#if DEBUG
@available(iOS 15.0, *)
var Current = World.live
#else
@available(iOS 15.0, *)
let Current = World.live
#endif

#endif

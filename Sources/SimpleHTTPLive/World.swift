import Foundation

struct World {
  var session: Session

  struct Session {
    var request: (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> Void
  }
}

extension World {
  static var live: Self {
    Self(
      session: Session(
        request: { request, completion in
          URLSession.shared
            .dataTask(with: request, completionHandler: completion)
            .resume()
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
          request: { _, _ in }
        )
      )
    }

    /// A World implementation that always fails when called.
    /// Used for testing purpose only.
    static var failing: Self {
      Self(
        session: Session(
          request: { _, _ in
            // TODO: instead of crashing, use pointfree's xctest-dynamic-overlay package.
            fatalError("Session.request(_:completion:) is not implemented!")
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

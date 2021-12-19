import AsyncCompatibilityKit
import Foundation
import XCTestDynamicOverlay

public struct World {
  public var session: Session

  public struct Session {
    public var request: (URLRequest) async throws -> (Data, URLResponse)

    public init(request: @escaping (URLRequest) async throws -> (Data, URLResponse)) {
      self.request = request
    }
  }

  public init(session: Session) {
    self.session = session
  }
}

extension World {
  static var live: World {
    World(
      session: Session(
        request: { try await URLSession.shared.data(for: $0) }
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
            (Data(), HTTPURLResponse.noop)
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
            XCTFail("Session.request(_:) is not implemented!")
            return (Data(), HTTPURLResponse.failing)
          }
        )
      )
    }
  #endif
}

#if DEBUG
  public var Current = World.live
#else
  let Current = World.live
#endif

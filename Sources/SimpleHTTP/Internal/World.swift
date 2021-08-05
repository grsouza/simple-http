import Foundation

struct World {
  var request: (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> Void
}

extension World {
  static var live: Self {
    Self(
      request: { request, completion in
        URLSession.shared
          .dataTask(with: request, completionHandler: completion)
          .resume()
      }
    )
  }
}

#if DEBUG
  var Current = World.live
#else
  let Current = World.live
#endif

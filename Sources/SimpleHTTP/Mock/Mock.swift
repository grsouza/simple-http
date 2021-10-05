import Foundation
import XCTestDynamicOverlay

#if DEBUG
extension HTTPClient {
    
    public static var noop: HTTPClient {
        HTTPClient(request: { _ in fatalError() })
    }
    
    public static var failing: HTTPClient {
        HTTPClient(request: { _ in fatalError() })
    }
}
#endif

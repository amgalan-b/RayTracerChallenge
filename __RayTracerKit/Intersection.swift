import Foundation

struct Intersection {

    let time: Double
    let object: Sphere
}

extension Intersection: Equatable {
}

#if TEST
import XCTest

final class IntersectionTests: XCTestCase {
}
#endif

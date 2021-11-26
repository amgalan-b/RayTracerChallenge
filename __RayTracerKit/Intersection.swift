import Foundation

struct Intersection {

    let time: Double
    let object: Shape
}

extension Intersection: Equatable {
}

#if TEST
import XCTest

final class IntersectionTests: XCTestCase {
}
#endif

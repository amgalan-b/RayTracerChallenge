import Foundation

struct Intersection {

    let time: Double
    let object: Shape
    let additionalData: ShapeIntersectionData?

    init(time: Double, object: Shape, additionalData: ShapeIntersectionData? = nil) {
        self.time = time
        self.object = object
        self.additionalData = additionalData
    }
}

extension Intersection: Equatable {

    static func == (lhs: Intersection, rhs: Intersection) -> Bool {
        return lhs.time == rhs.time && lhs.object == rhs.object
    }
}

/// Shapes may include additional data to the intersection.
protocol ShapeIntersectionData {
}

#if TEST
import XCTest

final class IntersectionTests: XCTestCase {
}
#endif

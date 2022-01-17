import Foundation

final class BoundingBox {

    var minimum: Tuple
    var maximum: Tuple

    init(
        minimum: Tuple = .point(.infinity, .infinity, .infinity),
        maximum: Tuple = .point(-.infinity, -.infinity, -.infinity)
    ) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func addPoint(_ point: Tuple) {
        minimum.x = min(point.x, minimum.x)
        minimum.y = min(point.y, minimum.y)
        minimum.z = min(point.z, minimum.z)

        maximum.x = max(point.x, maximum.x)
        maximum.y = max(point.y, maximum.y)
        maximum.z = max(point.z, maximum.z)
    }
}

#if TEST
import XCTest

final class BoundingBoxTests: XCTestCase {

    func test_addPoint() {
        let box = BoundingBox()
        box.addPoint(.point(-5, 2, 0))
        box.addPoint(.point(7, 0, -3))

        XCTAssertEqual(box.minimum, .point(-5, 0, -3))
        XCTAssertEqual(box.maximum, .point(7, 2, 0))
    }
}
#endif

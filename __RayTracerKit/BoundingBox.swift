import Foundation

final class BoundingBox {

    var minimum: Tuple
    var maximum: Tuple

    init(
        minimum: Tuple = .point(.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude),
        maximum: Tuple = .point(-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude)
    ) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func contains(_ point: Tuple) -> Bool {
        return (minimum.x ... maximum.x).contains(point.x)
            && (minimum.y ... maximum.y).contains(point.y)
            && (minimum.z ... maximum.z).contains(point.z)
    }

    func contains(_ otherBox: BoundingBox) -> Bool {
        return contains(otherBox.minimum) && contains(otherBox.maximum)
    }

    func addPoint(_ point: Tuple) {
        minimum.x = min(point.x, minimum.x)
        minimum.y = min(point.y, minimum.y)
        minimum.z = min(point.z, minimum.z)

        maximum.x = max(point.x, maximum.x)
        maximum.y = max(point.y, maximum.y)
        maximum.z = max(point.z, maximum.z)
    }

    func merge(with otherBox: BoundingBox) {
        addPoint(otherBox.minimum)
        addPoint(otherBox.maximum)
    }
}

protocol BoundableShape {

    func boundingBox() -> BoundingBox
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

    func test_merge() {
        let b1 = BoundingBox(minimum: .point(-5, -2, 0), maximum: .point(7, 4, 4))
        let b2 = BoundingBox(minimum: .point(8, -7, -2), maximum: .point(14, 2, 8))
        b1.merge(with: b2)

        XCTAssertEqual(b1.minimum, .point(-5, -7, -2))
        XCTAssertEqual(b1.maximum, .point(14, 4, 8))
    }

    func test_contains() {
        let box = BoundingBox(minimum: .point(5, -2, 0), maximum: .point(11, 4, 7))

        XCTAssert(box.contains(.point(5, -2, 0)))
        XCTAssert(box.contains(.point(11, 4, 7)))
        XCTAssert(box.contains(.point(8, 1, 3)))
        XCTAssertFalse(box.contains(.point(3, 0, 3)))
        XCTAssertFalse(box.contains(.point(8, -4, 3)))
        XCTAssertFalse(box.contains(.point(8, 1, -1)))
        XCTAssertFalse(box.contains(.point(13, 1, 3)))
        XCTAssertFalse(box.contains(.point(8, 5, 3)))
        XCTAssertFalse(box.contains(.point(8, 1, 8)))
    }

    func test_contains_box() {
        let b1 = BoundingBox(minimum: .point(5, -2, 0), maximum: .point(11, 4, 7))

        let b2 = BoundingBox(minimum: .point(5, -2, 0), maximum: .point(11, 4, 7))
        let b3 = BoundingBox(minimum: .point(6, -1, 1), maximum: .point(10, 3, 6))
        let b4 = BoundingBox(minimum: .point(4, -3, -1), maximum: .point(10, 3, 6))
        let b5 = BoundingBox(minimum: .point(6, -1, 1), maximum: .point(12, 5, 8))

        XCTAssert(b1.contains(b2))
        XCTAssert(b1.contains(b3))
        XCTAssertFalse(b1.contains(b4))
        XCTAssertFalse(b1.contains(b5))
    }
}
#endif

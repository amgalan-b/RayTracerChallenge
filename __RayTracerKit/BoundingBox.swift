import Foundation

struct BoundingBox {

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

    mutating func addPoint(_ point: Tuple) {
        minimum.x = min(point.x, minimum.x)
        minimum.y = min(point.y, minimum.y)
        minimum.z = min(point.z, minimum.z)

        maximum.x = max(point.x, maximum.x)
        maximum.y = max(point.y, maximum.y)
        maximum.z = max(point.z, maximum.z)
    }

    func merge(with otherBox: BoundingBox) -> BoundingBox {
        var copy = self
        copy.addPoint(otherBox.minimum)
        copy.addPoint(otherBox.maximum)

        return copy
    }

    func transformed(_ transform: Matrix) -> BoundingBox {
        let p1 = minimum
        let p2 = Tuple.point(minimum.x, minimum.y, maximum.z)
        let p3 = Tuple.point(minimum.x, maximum.y, minimum.z)
        let p4 = Tuple.point(minimum.x, maximum.y, maximum.z)
        let p5 = Tuple.point(maximum.x, minimum.y, minimum.z)
        let p6 = Tuple.point(maximum.x, maximum.y, minimum.z)
        let p7 = Tuple.point(maximum.x, maximum.y, maximum.z)
        let p8 = maximum

        var copy = self
        for point in [p1, p2, p3, p4, p5, p6, p7, p8] {
            copy.addPoint(transform * point)
        }

        return copy
    }

    func isIntersected(by ray: Ray) -> Bool {
        let times = Cube.intersectionTimes(for: ray)
        return !times.isEmpty
    }
}

#if TEST
import XCTest

final class BoundingBoxTests: XCTestCase {

    func test_addPoint() {
        var box = BoundingBox()
        box.addPoint(.point(-5, 2, 0))
        box.addPoint(.point(7, 0, -3))

        XCTAssertEqual(box.minimum, .point(-5, 0, -3))
        XCTAssertEqual(box.maximum, .point(7, 2, 0))
    }

    func test_merge() {
        let b1 = BoundingBox(minimum: .point(-5, -2, 0), maximum: .point(7, 4, 4))
        let b2 = BoundingBox(minimum: .point(8, -7, -2), maximum: .point(14, 2, 8))
        let b3 = b1.merge(with: b2)

        XCTAssertEqual(b3.minimum, .point(-5, -7, -2))
        XCTAssertEqual(b3.maximum, .point(14, 4, 8))
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

    func test_transformed() {
        let b1 = BoundingBox(minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
        let b2 = b1.transformed(.rotationX(.pi / 4) * .rotationY(.pi / 4))

        XCTAssertEqual(b2.minimum, .point(-1.41421, -1.7071, -1.7071))
        XCTAssertEqual(b2.maximum, .point(1.41421, 1.7071, 1.7071))
    }

    func test_isIntersected() {
        let box = BoundingBox(minimum: .point(-1, -1, -1), maximum: .point(1, 1, 1))
        let r1 = Ray(origin: .point(5, 0.5, 0), direction: .vector(-1, 0, 0))
        let r2 = Ray(origin: .point(-5, 0.5, 0), direction: .vector(1, 0, 0))
        let r3 = Ray(origin: .point(0.5, 5, 0), direction: .vector(0, -1, 0))
        let r4 = Ray(origin: .point(0.5, -5, 0), direction: .vector(0, 1, 0))
        let r5 = Ray(origin: .point(0.5, 0, 5), direction: .vector(0, 0, -1))
        let r6 = Ray(origin: .point(0.5, 0, -5), direction: .vector(0, 0, 1))

        let r7 = Ray(origin: .point(-2, 0, 0), direction: .vector(2, 4, 6))
        let r8 = Ray(origin: .point(0, -2, 0), direction: .vector(6, 2, 4))
        let r9 = Ray(origin: .point(0, 0, -2), direction: .vector(4, 6, 2))
        let r10 = Ray(origin: .point(2, 0, 2), direction: .vector(0, 0, -1))
        let r11 = Ray(origin: .point(0, 2, 2), direction: .vector(0, -1, 0))
        let r12 = Ray(origin: .point(2, 2, 0), direction: .vector(-1, 0, 0))

        XCTAssert(box.isIntersected(by: r1))
        XCTAssert(box.isIntersected(by: r2))
        XCTAssert(box.isIntersected(by: r3))
        XCTAssert(box.isIntersected(by: r4))
        XCTAssert(box.isIntersected(by: r5))
        XCTAssert(box.isIntersected(by: r6))

        XCTAssertFalse(box.isIntersected(by: r7))
        XCTAssertFalse(box.isIntersected(by: r8))
        XCTAssertFalse(box.isIntersected(by: r9))
        XCTAssertFalse(box.isIntersected(by: r10))
        XCTAssertFalse(box.isIntersected(by: r11))
        XCTAssertFalse(box.isIntersected(by: r12))
    }
}
#endif

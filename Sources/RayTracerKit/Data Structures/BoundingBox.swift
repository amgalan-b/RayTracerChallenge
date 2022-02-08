import Foundation

struct BoundingBox {

    private(set) var minimum: Point
    private(set) var maximum: Point

    init(
        minimum: Point = Point(.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude),
        maximum: Point = Point(-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude)
    ) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func contains(_ point: Point) -> Bool {
        return (minimum.x ... maximum.x).contains(point.x)
            && (minimum.y ... maximum.y).contains(point.y)
            && (minimum.z ... maximum.z).contains(point.z)
    }

    func contains(_ otherBox: BoundingBox) -> Bool {
        return contains(otherBox.minimum) && contains(otherBox.maximum)
    }

    mutating func addPoint(_ point: Point) {
        minimum = Point(
            min(minimum.x, point.x),
            min(minimum.y, point.y),
            min(minimum.z, point.z)
        )
        maximum = Point(
            max(maximum.x, point.x),
            max(maximum.y, point.y),
            max(maximum.z, point.z)
        )
    }

    func merge(with otherBox: BoundingBox) -> BoundingBox {
        var copy = self
        copy.addPoint(otherBox.minimum)
        copy.addPoint(otherBox.maximum)

        return copy
    }

    func transformed(_ transform: Matrix) -> BoundingBox {
        let p1 = minimum
        let p2 = Point(minimum.x, minimum.y, maximum.z)
        let p3 = Point(minimum.x, maximum.y, minimum.z)
        let p4 = Point(minimum.x, maximum.y, maximum.z)
        let p5 = Point(maximum.x, minimum.y, minimum.z)
        let p6 = Point(maximum.x, maximum.y, minimum.z)
        let p7 = Point(maximum.x, maximum.y, maximum.z)
        let p8 = maximum

        var copy = BoundingBox()
        for point in [p1, p2, p3, p4, p5, p6, p7, p8] {
            copy.addPoint(transform * point)
        }

        return copy
    }

    func isIntersected(by ray: Ray) -> Bool {
        let times = Cube.intersectionTimes(for: ray, minimum: minimum, maximum: maximum)
        return !times.isEmpty
    }

    func split() -> (BoundingBox, BoundingBox) {
        var x0 = minimum.x
        var y0 = minimum.y
        var z0 = minimum.z
        var x1 = maximum.x
        var y1 = maximum.y
        var z1 = maximum.z

        let dx = maximum.x - minimum.x
        let dy = maximum.y - minimum.y
        let dz = maximum.z - minimum.z

        switch max(dx, dy, dz) {
        case dx:
            x0 = x0 + dx / 2.0
            x1 = x0
        case dy:
            y0 = y0 + dy / 2.0
            y1 = y0
        case dz:
            z0 = z0 + dz / 2.0
            z1 = z0
        default:
            fatalError()
        }

        let minMid = Point(x0, y0, z0)
        let maxMid = Point(x1, y1, z1)

        let left = BoundingBox(minimum: minimum, maximum: maxMid)
        let right = BoundingBox(minimum: minMid, maximum: maximum)

        return (left, right)
    }
}

#if TEST
import XCTest

final class BoundingBoxTests: XCTestCase {

    func test_addPoint() {
        var box = BoundingBox()
        box.addPoint(Point(-5, 2, 0))
        box.addPoint(Point(7, 0, -3))

        XCTAssertEqual(box.minimum, Point(-5, 0, -3))
        XCTAssertEqual(box.maximum, Point(7, 2, 0))
    }

    func test_merge() {
        let b1 = BoundingBox(minimum: Point(-5, -2, 0), maximum: Point(7, 4, 4))
        let b2 = BoundingBox(minimum: Point(8, -7, -2), maximum: Point(14, 2, 8))
        let b3 = b1.merge(with: b2)

        XCTAssertEqual(b3.minimum, Point(-5, -7, -2))
        XCTAssertEqual(b3.maximum, Point(14, 4, 8))
    }

    func test_contains() {
        let box = BoundingBox(minimum: Point(5, -2, 0), maximum: Point(11, 4, 7))

        XCTAssert(box.contains(Point(5, -2, 0)))
        XCTAssert(box.contains(Point(11, 4, 7)))
        XCTAssert(box.contains(Point(8, 1, 3)))
        XCTAssertFalse(box.contains(Point(3, 0, 3)))
        XCTAssertFalse(box.contains(Point(8, -4, 3)))
        XCTAssertFalse(box.contains(Point(8, 1, -1)))
        XCTAssertFalse(box.contains(Point(13, 1, 3)))
        XCTAssertFalse(box.contains(Point(8, 5, 3)))
        XCTAssertFalse(box.contains(Point(8, 1, 8)))
    }

    func test_contains_box() {
        let b1 = BoundingBox(minimum: Point(5, -2, 0), maximum: Point(11, 4, 7))

        let b2 = BoundingBox(minimum: Point(5, -2, 0), maximum: Point(11, 4, 7))
        let b3 = BoundingBox(minimum: Point(6, -1, 1), maximum: Point(10, 3, 6))
        let b4 = BoundingBox(minimum: Point(4, -3, -1), maximum: Point(10, 3, 6))
        let b5 = BoundingBox(minimum: Point(6, -1, 1), maximum: Point(12, 5, 8))

        XCTAssert(b1.contains(b2))
        XCTAssert(b1.contains(b3))
        XCTAssertFalse(b1.contains(b4))
        XCTAssertFalse(b1.contains(b5))
    }

    func test_transformed() {
        let b1 = BoundingBox(minimum: Point(-1, -1, -1), maximum: Point(1, 1, 1))
        let b2 = b1.transformed(.rotationX(.pi / 4) * .rotationY(.pi / 4))

        XCTAssertEqual(b2.minimum, Point(-1.41421, -1.7071, -1.7071))
        XCTAssertEqual(b2.maximum, Point(1.41421, 1.7071, 1.7071))
    }

    func test_isIntersected() {
        let box = BoundingBox(minimum: Point(-1, -1, -1), maximum: Point(1, 1, 1))
        let r1 = Ray(origin: Point(5, 0.5, 0), direction: Vector(-1, 0, 0))
        let r2 = Ray(origin: Point(-5, 0.5, 0), direction: Vector(1, 0, 0))
        let r3 = Ray(origin: Point(0.5, 5, 0), direction: Vector(0, -1, 0))
        let r4 = Ray(origin: Point(0.5, -5, 0), direction: Vector(0, 1, 0))
        let r5 = Ray(origin: Point(0.5, 0, 5), direction: Vector(0, 0, -1))
        let r6 = Ray(origin: Point(0.5, 0, -5), direction: Vector(0, 0, 1))

        let r7 = Ray(origin: Point(-2, 0, 0), direction: Vector(2, 4, 6))
        let r8 = Ray(origin: Point(0, -2, 0), direction: Vector(6, 2, 4))
        let r9 = Ray(origin: Point(0, 0, -2), direction: Vector(4, 6, 2))
        let r10 = Ray(origin: Point(2, 0, 2), direction: Vector(0, 0, -1))
        let r11 = Ray(origin: Point(0, 2, 2), direction: Vector(0, -1, 0))
        let r12 = Ray(origin: Point(2, 2, 0), direction: Vector(-1, 0, 0))

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

    func test_isIntersected_nonCubic() {
        let box = BoundingBox(minimum: Point(5, -2, 0), maximum: Point(11, 4, 7))

        let r1 = Ray(origin: Point(15, 1, 2), direction: Vector(-1, 0, 0))
        let r2 = Ray(origin: Point(-5, -1, 4), direction: Vector(1, 0, 0))
        let r3 = Ray(origin: Point(7, 6, 5), direction: Vector(0, -1, 0))
        let r4 = Ray(origin: Point(9, -5, 6), direction: Vector(0, 1, 0))
        let r5 = Ray(origin: Point(8, 2, 12), direction: Vector(0, 0, -1))
        let r6 = Ray(origin: Point(6, 0, -5), direction: Vector(0, 0, 1))
        let r7 = Ray(origin: Point(8, 1, 3.5), direction: Vector(0, 0, 1))
        let r8 = Ray(origin: Point(9, -1, -8), direction: Vector(2, 4, 6))
        let r9 = Ray(origin: Point(8, 3, -4), direction: Vector(6, 2, 4))
        let r10 = Ray(origin: Point(9, -1, -2), direction: Vector(4, 6, 2))
        let r11 = Ray(origin: Point(4, 0, 9), direction: Vector(0, 0, -1))
        let r12 = Ray(origin: Point(8, 6, -1), direction: Vector(0, -1, 0))
        let r13 = Ray(origin: Point(12, 5, 4), direction: Vector(-1, 0, 0))

        XCTAssert(box.isIntersected(by: r1))
        XCTAssert(box.isIntersected(by: r2))
        XCTAssert(box.isIntersected(by: r3))
        XCTAssert(box.isIntersected(by: r4))
        XCTAssert(box.isIntersected(by: r5))
        XCTAssert(box.isIntersected(by: r6))
        XCTAssert(box.isIntersected(by: r7))

        XCTAssertFalse(box.isIntersected(by: r8))
        XCTAssertFalse(box.isIntersected(by: r9))
        XCTAssertFalse(box.isIntersected(by: r10))
        XCTAssertFalse(box.isIntersected(by: r11))
        XCTAssertFalse(box.isIntersected(by: r12))
        XCTAssertFalse(box.isIntersected(by: r13))
    }

    func test_split() {
        let box = BoundingBox(minimum: Point(-1, -4, -5), maximum: Point(9, 6, 5))
        let (left, right) = box.split()

        XCTAssertEqual(left.minimum, Point(-1, -4, -5))
        XCTAssertEqual(left.maximum, Point(4, 6, 5))
        XCTAssertEqual(right.minimum, Point(4, -4, -5))
        XCTAssertEqual(right.maximum, Point(9, 6, 5))
    }

    func test_split_xWide() {
        let box = BoundingBox(minimum: Point(-1, -2, -3), maximum: Point(9, 5.5, 3))
        let (left, right) = box.split()

        XCTAssertEqual(left.minimum, Point(-1, -2, -3))
        XCTAssertEqual(left.maximum, Point(4, 5.5, 3))
        XCTAssertEqual(right.minimum, Point(4, -2, -3))
        XCTAssertEqual(right.maximum, Point(9, 5.5, 3))
    }

    func test_split_yWide() {
        let box = BoundingBox(minimum: Point(-1, -2, -3), maximum: Point(5, 8, 3))
        let (left, right) = box.split()

        XCTAssertEqual(left.minimum, Point(-1, -2, -3))
        XCTAssertEqual(left.maximum, Point(5, 3, 3))
        XCTAssertEqual(right.minimum, Point(-1, 3, -3))
        XCTAssertEqual(right.maximum, Point(5, 8, 3))
    }

    func test_split_zWide() {
        let box = BoundingBox(minimum: Point(-1, -2, -3), maximum: Point(5, 3, 7))
        let (left, right) = box.split()

        XCTAssertEqual(left.minimum, Point(-1, -2, -3))
        XCTAssertEqual(left.maximum, Point(5, 3, 2))
        XCTAssertEqual(right.minimum, Point(-1, -2, 2))
        XCTAssertEqual(right.maximum, Point(5, 3, 7))
    }
}
#endif

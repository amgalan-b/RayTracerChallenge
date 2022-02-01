import Foundation

public struct Point: Tuple {

    var xyzw: SIMD4<Double>

    init(xyzw: SIMD4<Double>) {
        assert(xyzw.w != 0)
        self.xyzw = xyzw
    }

    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double = 1) {
        self.xyzw = SIMD4(x: x, y: y, z: z, w: w)
    }
}

extension Point {

    static func + (lhs: Point, rhs: Vector) -> Point {
        return Point(xyzw: lhs.xyzw + rhs.xyzw)
    }

    static func - (lhs: Point, rhs: Point) -> Vector {
        return Vector(xyzw: lhs.xyzw - rhs.xyzw)
    }

    static func - (lhs: Point, rhs: Vector) -> Point {
        return Point(xyzw: lhs.xyzw - rhs.xyzw)
    }
}

#if TEST
import XCTest

final class PointTests: XCTestCase {

    func test_add() {
        let t1 = Point(3, -2, 5)
        let t2 = Vector(-2, 3, 1)

        XCTAssertEqual(t1 + t2, Point(1, 1, 6))
    }

    func test_subtract_twoPoints() {
        let p1 = Point(3, 2, 1)
        let p2 = Point(5, 6, 7)

        XCTAssertEqual(p1 - p2, Vector(-2, -4, -6))
    }

    func test_subtract_vectorFromPoint() {
        let point = Point(3, 2, 1)
        let vector = Vector(5, 6, 7)

        XCTAssertEqual(point - vector, Point(-2, -4, -6))
    }
}
#endif

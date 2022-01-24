import Foundation

extension Tuple {

    static func + (lhs: Self, rhs: Self) -> Self {
        return Tuple(xyzw: lhs.xyzw + rhs.xyzw)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Tuple(xyzw: lhs.xyzw - rhs.xyzw)
    }

    static func * (lhs: Self, rhs: Double) -> Self {
        return Tuple(xyzw: lhs.xyzw * rhs)
    }

    static func / (lhs: Self, rhs: Double) -> Self {
        return Tuple(xyzw: lhs.xyzw / rhs)
    }

    static prefix func - (lhs: Self) -> Self {
        return Tuple(xyzw: -lhs.xyzw)
    }
}

#if TEST
import XCTest

extension TupleTests {

    func test_add() {
        let t1 = Tuple(3, -2, 5, 1)
        let t2 = Tuple(-2, 3, 1, 0)

        XCTAssertEqual(t1 + t2, Tuple(1, 1, 6, 1))
    }

    func test_subtract_twoPoints() {
        let p1 = Tuple.point(3, 2, 1)
        let p2 = Tuple.point(5, 6, 7)

        XCTAssertEqual(p1 - p2, .vector(-2, -4, -6))
    }

    func test_subtract_vectorFromPoint() {
        let point = Tuple.point(3, 2, 1)
        let vector = Tuple.vector(5, 6, 7)

        XCTAssertEqual(point - vector, .point(-2, -4, -6))
    }

    func test_subtract_twoVectors() {
        let v1 = Tuple.vector(3, 2, 1)
        let v2 = Tuple.vector(5, 6, 7)

        XCTAssertEqual(v1 - v2, .vector(-2, -4, -6))
    }

    func test_negate() {
        let tuple = Tuple(1, -2, 3, -4)
        XCTAssertEqual(-tuple, Tuple(-1, 2, -3, 4))
    }

    func test_multiply_scalar() {
        let tuple = Tuple(1, -2, 3, -4)
        XCTAssertEqual(tuple * 3.5, Tuple(3.5, -7, 10.5, -14))
    }

    func test_multiply_fraction() {
        let tuple = Tuple(1, -2, 3, -4)
        XCTAssertEqual(tuple * 0.5, Tuple(0.5, -1, 1.5, -2))
    }

    func test_divide_scalar() {
        let tuple = Tuple(1, -2, 3, -4)
        XCTAssertEqual(tuple / 2, Tuple(0.5, -1, 1.5, -2))
    }
}
#endif

import Babbage
import simd

struct Tuple {

    private let _tuple: SIMD4<Double>

    init(_ tuple: SIMD4<Double>) {
        _tuple = tuple
    }

    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        _tuple = [x, y, z, w]
    }

    var isPoint: Bool {
        return _tuple.w > 0
    }

    var isVector: Bool {
        return _tuple.w == 0
    }

    var magnitude: Double {
        return sqrt(_tuple.x.pow(2) + _tuple.y.pow(2) + _tuple.z.pow(2) + _tuple.w.pow(2))
    }
}

extension Tuple {

    static func point(_ x: Double, _ y: Double, _ z: Double) -> Tuple {
        return Tuple(x, y, z, 1)
    }

    static func vector(_ x: Double, _ y: Double, _ z: Double) -> Tuple {
        return Tuple(x, y, z, 0)
    }
}

extension Tuple: Equatable {
}

extension Tuple {

    static func + (lhs: Self, rhs: Self) -> Self {
        return Tuple(lhs._tuple + rhs._tuple)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Tuple(lhs._tuple - rhs._tuple)
    }

    static func * (lhs: Self, rhs: Double) -> Self {
        return Tuple(lhs._tuple * rhs)
    }

    static func / (lhs: Self, rhs: Double) -> Self {
        return Tuple(lhs._tuple / rhs)
    }

    static prefix func - (lhs: Self) -> Self {
        return Tuple(-lhs._tuple)
    }
}

#if TEST
import XCTest

final class TupleTests: XCTestCase {

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

    func test_magnitude() {
        let v1 = Tuple.vector(1, 0, 0)
        let v2 = Tuple.vector(0, 1, 0)
        let v3 = Tuple.vector(0, 0, 1)
        let v4 = Tuple.vector(1, 2, 3)
        let v5 = Tuple.vector(-1, -2, -3)

        XCTAssertEqual(v1.magnitude, 1)
        XCTAssertEqual(v2.magnitude, 1)
        XCTAssertEqual(v3.magnitude, 1)
        XCTAssertEqual(v4.magnitude, 14.squareRoot())
        XCTAssertEqual(v5.magnitude, 14.squareRoot())
    }
}
#endif

import Foundation
import simd

protocol Tuple: Equatable {

    var xyzw: SIMD4<Double> { get set }

    init(xyzw: SIMD4<Double>)

    init(_ x: Double, _ y: Double, _ z: Double)
}

extension Tuple {

    var x: Double {
        return xyzw.x
    }

    var y: Double {
        return xyzw.y
    }

    var z: Double {
        return xyzw.z
    }

    var w: Double {
        return xyzw.w
    }

    var magnitude: Double {
        return sqrt(xyzw.x.pow(2) + xyzw.y.pow(2) + xyzw.z.pow(2) + xyzw.w.pow(2))
    }

    func dotProduct(with other: Self) -> Double {
        return simd_dot(xyzw, other.xyzw)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.xyzw.x.isAlmostEqual(to: rhs.xyzw.x, tolerance: .tolerance)
            && lhs.xyzw.y.isAlmostEqual(to: rhs.xyzw.y, tolerance: .tolerance)
            && lhs.xyzw.z.isAlmostEqual(to: rhs.xyzw.z, tolerance: .tolerance)
            && lhs.xyzw.w.isAlmostEqual(to: rhs.xyzw.w, tolerance: .tolerance)
    }
}

extension Tuple {

    static func * (lhs: Self, rhs: Double) -> Self {
        return Self(xyzw: lhs.xyzw * rhs)
    }

    static func / (lhs: Self, rhs: Double) -> Self {
        return Self(xyzw: lhs.xyzw / rhs)
    }

    static prefix func - (lhs: Self) -> Self {
        return Self(xyzw: -lhs.xyzw)
    }
}

extension Tuple {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let values = try container.decodeArray(of: Double.self)

        guard values.count == 3 else {
            fatalError()
        }

        self.init(values[0], values[1], values[2])
    }
}

#if TEST
import XCTest

final class TupleTests: XCTestCase {

    func test_negate() {
        let point = Point(1, -2, 3, -4)
        XCTAssertEqual(-point, Point(-1, 2, -3, 4))
    }

    func test_multiply_scalar() {
        let point = Point(1, -2, 3, -4)
        XCTAssertEqual(point * 3.5, Point(3.5, -7, 10.5, -14))
    }

    func test_multiply_fraction() {
        let point = Point(1, -2, 3, -4)
        XCTAssertEqual(point * 0.5, Point(0.5, -1, 1.5, -2))
    }

    func test_divide_scalar() {
        let point = Point(1, -2, 3, -4)
        XCTAssertEqual(point / 2, Point(0.5, -1, 1.5, -2))
    }
}
#endif

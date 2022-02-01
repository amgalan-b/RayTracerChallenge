import Foundation
import simd

protocol Tuple: Equatable {

    var xyzw: SIMD4<Double> { get set }

    init(xyzw: SIMD4<Double>)
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

public struct Vector: Tuple {

    var xyzw: SIMD4<Double>

    init(xyzw: SIMD4<Double>) {
        assert(xyzw.w == 0)
        self.xyzw = xyzw
    }

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.xyzw = SIMD4(x: x, y: y, z: z, w: 0)
    }

    func normalized() -> Vector {
        return Vector(xyzw: simd_normalize(xyzw))
    }

    func crossProduct(with other: Vector) -> Vector {
        let xyz = simd_cross(xyzw.xyz, other.xyzw.xyz)
        return Vector(xyzw: SIMD4(xyz, 0))
    }

    func reflected(on normal: Vector) -> Vector {
        return self - normal * 2 * dotProduct(with: normal)
    }
}

#if TEST
import XCTest

final class _TupleTests: XCTestCase {

    func test_magnitude() {
        let v1 = Vector(1, 0, 0)
        let v2 = Vector(0, 1, 0)
        let v3 = Vector(0, 0, 1)
        let v4 = Vector(1, 2, 3)
        let v5 = Vector(-1, -2, -3)

        XCTAssertEqual(v1.magnitude, 1)
        XCTAssertEqual(v2.magnitude, 1)
        XCTAssertEqual(v3.magnitude, 1)
        XCTAssertEqual(v4.magnitude, 14.squareRoot())
        XCTAssertEqual(v5.magnitude, 14.squareRoot())
    }

    func test_normalized() {
        let vector = Vector(4, 0, 0)
        XCTAssertEqual(vector.normalized(), Vector(1, 0, 0))
    }

    func test_magnitude_normalizedVector() {
        let vector = Vector(1, 2, 3)
        XCTAssertEqual(vector.normalized().magnitude, 1)
    }

    func test_dotProduct() {
        let v1 = Vector(1, 2, 3)
        let v2 = Vector(2, 3, 4)

        XCTAssertEqual(v1.dotProduct(with: v2), 20)
    }

    func test_crossProduct() {
        let v1 = Vector(1, 2, 3)
        let v2 = Vector(2, 3, 4)

        XCTAssertEqual(v1.crossProduct(with: v2), Vector(-1, 2, -1))
        XCTAssertEqual(v2.crossProduct(with: v1), Vector(1, -2, 1))
    }

    func test_reflected_45Degrees() {
        let reflection = Vector(1, -1, 0)
            .reflected(on: Vector(0, 1, 0))

        XCTAssertEqual(reflection, Vector(1, 1, 0))
    }

    func test_reflected_slanted() {
        let reflection = Vector(0, -1, 0)
            .reflected(on: Vector(1, 1, 0).normalized())

        XCTAssertEqual(reflection, Vector(1, 0, 0))
    }
}
#endif

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

extension Vector {

    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(xyzw: lhs.xyzw + rhs.xyzw)
    }

    static func - (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(xyzw: lhs.xyzw - rhs.xyzw)
    }
}

#if TEST
import XCTest

extension _TupleTests {

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

    func test_subtract_twoVectors() {
        let v1 = Vector(3, 2, 1)
        let v2 = Vector(5, 6, 7)

        XCTAssertEqual(v1 - v2, Vector(-2, -4, -6))
    }

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

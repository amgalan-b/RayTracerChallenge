import Babbage
import simd

struct Tuple {

    private let _xyzw: SIMD4<Double>

    init(xyzw: SIMD4<Double>) {
        _xyzw = xyzw
    }

    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        _xyzw = [x, y, z, w]
    }

    var xyzw: SIMD4<Double> {
        return _xyzw
    }

    var isPoint: Bool {
        return _xyzw.w > 0
    }

    var isVector: Bool {
        return _xyzw.w == 0
    }

    var magnitude: Double {
        return sqrt(_xyzw.x.pow(2) + _xyzw.y.pow(2) + _xyzw.z.pow(2) + _xyzw.w.pow(2))
    }

    func normalized() -> Self {
        return Tuple(xyzw: simd_normalize(_xyzw))
    }

    func dotProduct(with tuple: Self) -> Double {
        return simd_dot(_xyzw, tuple._xyzw)
    }

    func crossProduct(with tuple: Self) -> Self {
        let xyz = simd_cross(_xyzw.xyz, tuple._xyzw.xyz)
        return Tuple(xyzw: SIMD4(xyz, 0))
    }
}

extension Tuple: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.xyzw.x.isAlmostEqual(to: rhs.xyzw.x)
            && lhs.xyzw.y.isAlmostEqual(to: rhs.xyzw.y)
            && lhs.xyzw.z.isAlmostEqual(to: rhs.xyzw.z)
            && lhs.xyzw.w.isAlmostEqual(to: rhs.xyzw.w)
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

#if TEST
import XCTest

final class TupleTests: XCTestCase {

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

    func test_normalized() {
        let vector = Tuple.vector(4, 0, 0)
        XCTAssertEqual(vector.normalized(), .vector(1, 0, 0))
    }

    func test_magnitude_normalizedVector() {
        let vector = Tuple.vector(1, 2, 3)
        XCTAssertEqual(vector.normalized().magnitude, 1)
    }

    func test_dotProduct() {
        let v1 = Tuple.vector(1, 2, 3)
        let v2 = Tuple.vector(2, 3, 4)

        XCTAssertEqual(v1.dotProduct(with: v2), 20)
    }

    func test_crossProduct() {
        let v1 = Tuple.vector(1, 2, 3)
        let v2 = Tuple.vector(2, 3, 4)

        XCTAssertEqual(v1.crossProduct(with: v2), .vector(-1, 2, -1))
        XCTAssertEqual(v2.crossProduct(with: v1), .vector(1, -2, 1))
    }
}
#endif

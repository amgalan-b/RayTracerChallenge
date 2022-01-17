import Babbage
import simd

public struct Tuple {

    private var _xyzw: SIMD4<Double>

    init(xyzw: SIMD4<Double>) {
        _xyzw = xyzw
    }

    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        _xyzw = [x, y, z, w]
    }

    var x: Double {
        get { _xyzw.x }
        set { _xyzw.x = newValue }
    }

    var y: Double {
        get { _xyzw.y }
        set { _xyzw.y = newValue }
    }

    var z: Double {
        get { _xyzw.z }
        set { _xyzw.z = newValue }
    }

    var w: Double {
        return _xyzw.w
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

    func reflected(on normal: Self) -> Self {
        return self - normal * 2 * dotProduct(with: normal)
    }
}

extension Tuple: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.xyzw.x.isAlmostEqual(to: rhs.xyzw.x, tolerance: .tolerance)
            && lhs.xyzw.y.isAlmostEqual(to: rhs.xyzw.y, tolerance: .tolerance)
            && lhs.xyzw.z.isAlmostEqual(to: rhs.xyzw.z, tolerance: .tolerance)
            && lhs.xyzw.w.isAlmostEqual(to: rhs.xyzw.w, tolerance: .tolerance)
    }
}

extension Tuple {

    public static func point(_ x: Double, _ y: Double, _ z: Double) -> Tuple {
        return Tuple(x, y, z, 1)
    }

    public static func vector(_ x: Double, _ y: Double, _ z: Double) -> Tuple {
        return Tuple(x, y, z, 0)
    }
}

extension Tuple: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "[\(x), \(y), \(z), \(w)]"
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

    func test_reflected_45Degrees() {
        let reflection = Tuple.vector(1, -1, 0)
            .reflected(on: .vector(0, 1, 0))

        XCTAssertEqual(reflection, .vector(1, 1, 0))
    }

    func test_reflected_slanted() {
        let reflection = Tuple.vector(0, -1, 0)
            .reflected(on: .vector(1, 1, 0).normalized())

        XCTAssertEqual(reflection, .vector(1, 0, 0))
    }
}
#endif

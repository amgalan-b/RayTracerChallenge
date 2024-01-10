import Foundation
import simd

public struct Vector: Tuple {

    var xyzw: SIMD4<Double>

    init(xyzw: SIMD4<Double>) {
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

extension Vector: Decodable {
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
import Yams

final class VectorTests: XCTestCase {

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

    func test_subtract_twoVectors() {
        let v1 = Vector(3, 2, 1)
        let v2 = Vector(5, 6, 7)

        XCTAssertEqual(v1 - v2, Vector(-2, -4, -6))
    }

    func test_decode() {
        let content = "[-2, 1, 0.5]"
        let decoder = YAMLDecoder()
        let vector = try? decoder.decode(Vector.self, from: content)

        XCTAssertEqual(vector, Vector(-2, 1, 0.5))
    }
}
#endif

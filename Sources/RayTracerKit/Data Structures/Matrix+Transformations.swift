import Foundation
import simd

extension Matrix {

    public static func translation(_ deltaX: Double, _ deltaY: Double, _ deltaZ: Double) -> Self {
        return Matrix(
            [1, 0, 0, deltaX],
            [0, 1, 0, deltaY],
            [0, 0, 1, deltaZ],
            [0, 0, 0, 1]
        )
    }

    public static func scaling(_ factorX: Double, _ factorY: Double, _ factorZ: Double) -> Self {
        return Matrix(
            [factorX, 0, 0, 0],
            [0, factorY, 0, 0],
            [0, 0, factorZ, 0],
            [0, 0, 0, 1]
        )
    }

    public static func rotationX(_ radians: Double) -> Self {
        return Matrix(
            [1, 0, 0, 0],
            [0, cos(radians), -sin(radians), 0],
            [0, sin(radians), cos(radians), 0],
            [0, 0, 0, 1]
        )
    }

    public static func rotationY(_ radians: Double) -> Self {
        return Matrix(
            [cos(radians), 0, sin(radians), 0],
            [0, 1, 0, 0],
            [-sin(radians), 0, cos(radians), 0],
            [0, 0, 0, 1]
        )
    }

    public static func rotationZ(_ radians: Double) -> Self {
        return Matrix(
            [cos(radians), -sin(radians), 0, 0],
            [sin(radians), cos(radians), 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
    }

    public static func shearing(_ xy: Double, _ xz: Double, yx: Double, yz: Double, zx: Double, zy: Double) -> Self {
        return Matrix(
            [1, xy, xz, 0],
            [yx, 1, yz, 0],
            [zx, zy, 1, 0],
            [0, 0, 0, 1]
        )
    }
}

#if TEST
import XCTest

extension MatrixTests {

    func test_translation_multiplyPoint() {
        let transform = Matrix.translation(5, -3, 2)
        XCTAssertEqual(transform * Point(-3, 4, 5), Point(2, 1, 7))
    }

    func test_translation_multiplyPointWithInverseTranslation() {
        let transform = Matrix.translation(5, -3, 2)
            .inversed()
        XCTAssertEqual(transform * Point(-3, 4, 5), Point(-8, 7, 3))
    }

    func test_translation_multiplyVector() {
        let transform = Matrix.translation(5, -3, 2)
        XCTAssertEqual(transform * Vector(-3, 4, 5), Vector(-3, 4, 5))
    }

    func test_scaling_multiplyPoint() {
        let transform = Matrix.scaling(2, 3, 4)
        XCTAssertEqual(transform * Point(-4, 6, 8), Point(-8, 18, 32))
    }

    func test_scaling_multiplyVector() {
        let transform = Matrix.scaling(2, 3, 4)
        XCTAssertEqual(transform * Vector(-4, 6, 8), Vector(-8, 18, 32))
    }

    func test_scaling_multiplyVectorWithInverseScaling() {
        let transform = Matrix.scaling(2, 3, 4)
            .inversed()
        XCTAssertEqual(transform * Vector(-4, 6, 8), Vector(-2, 2, 2))
    }

    func test_scaling_negativeValueIsReflection() {
        let transform = Matrix.scaling(-1, 1, 1)
        XCTAssertEqual(transform * Point(2, 3, 4), Point(-2, 3, 4))
    }

    func test_rotationX() {
        let r1 = Matrix.rotationX(.pi / 4)
        let r2 = Matrix.rotationX(.pi / 2)

        XCTAssertEqual(r1 * Point(0, 1, 0), Point(0, 0.7071, 0.7071))
        XCTAssertEqual(r2 * Point(0, 1, 0), Point(0, 0, 1))
    }

    func test_rotationX_inverse() {
        let transform = Matrix.rotationX(.pi / 4)
            .inversed()

        XCTAssertEqual(transform * Point(0, 1, 0), Point(0, 0.7071, -0.7071))
    }

    func test_rotationY() {
        let r1 = Matrix.rotationY(.pi / 4)
        let r2 = Matrix.rotationY(.pi / 2)

        XCTAssertEqual(r1 * Point(0, 0, 1), Point(0.7071, 0, 0.7071))
        XCTAssertEqual(r2 * Point(0, 0, 1), Point(1, 0, 0))
    }

    func test_rotationZ() {
        let r1 = Matrix.rotationZ(.pi / 4)
        let r2 = Matrix.rotationZ(.pi / 2)

        XCTAssertEqual(r1 * Point(0, 1, 0), Point(-0.7071, 0.7071, 0))
        XCTAssertEqual(r2 * Point(0, 1, 0), Point(-1, 0, 0))
    }

    func test_shearing() {
        let transform = Matrix.shearing(1, 0, yx: 0, yz: 0, zx: 0, zy: 0)
        XCTAssertEqual(transform * Point(2, 3, 4), Point(5, 3, 4))
    }

    func test_transformationChainInSequence() {
        let p1 = Point(1, 0, 1)
        let p2 = Matrix.rotationX(.pi / 2) * p1
        let p3 = Matrix.scaling(5, 5, 5) * p2
        let p4 = Matrix.translation(10, 5, 7) * p3

        XCTAssertEqual(p4, Point(15, 0, 7))
    }

    func test_transformationChainInReverseOrder() {
        let point = Point(1, 0, 1)
        let transformation = Matrix.translation(10, 5, 7) * .scaling(5, 5, 5) * .rotationX(.pi / 2)

        XCTAssertEqual(transformation * point, Point(15, 0, 7))
    }
}
#endif

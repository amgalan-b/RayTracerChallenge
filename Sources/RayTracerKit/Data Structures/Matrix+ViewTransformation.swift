import Foundation

extension Matrix {

    public static func viewTransform(origin: Point, target: Point, orientation upVectorApproximated: Vector) -> Matrix {
        let forward = (target - origin).normalized()
        let upApproximated = upVectorApproximated.normalized()

        let left = forward.crossProduct(with: upApproximated)
        let up = left.crossProduct(with: forward)

        let orientation = Matrix(
            [left.x, left.y, left.z, 0],
            [up.x, up.y, up.z, 0],
            [-forward.x, -forward.y, -forward.z, 0],
            [0, 0, 0, 1]
        )

        return orientation * .translation(-origin.x, -origin.y, -origin.z)
    }
}

#if TEST
import XCTest

extension MatrixTests {

    func test_viewTransform_defaultOrientation() {
        let transform = Matrix.viewTransform(
            origin: Point(0, 0, 0),
            target: Point(0, 0, -1),
            orientation: Vector(0, 1, 0)
        )

        XCTAssertEqual(transform, .identity)
    }

    func test_viewTransform_zDirection() {
        let transform = Matrix.viewTransform(
            origin: Point(0, 0, 8),
            target: Point(0, 0, 0),
            orientation: Vector(0, 1, 0)
        )

        XCTAssertEqual(transform, .translation(0, 0, -8))
    }

    func test_viewTransform_arbitrary() {
        let transform = Matrix.viewTransform(
            origin: Point(1, 3, 2),
            target: Point(4, -2, 8),
            orientation: Vector(1, 1, 0)
        )
        let expected = Matrix(
            [-0.50709, 0.50709, 0.67612, -2.36643],
            [0.76772, 0.60609, 0.12122, -2.82843],
            [-0.35857, 0.59761, -0.71714, 0],
            [0, 0, 0, 1]
        )

        XCTAssertEqual(transform, expected)
    }
}
#endif

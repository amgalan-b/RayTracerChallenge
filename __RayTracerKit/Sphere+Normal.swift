import Foundation

extension Sphere {

    func normal(at worldPoint: Tuple) -> Tuple {
        let objectPoint = transform.inverted() * worldPoint
        let objectNormal = objectPoint - .point(0, 0, 0)
        let worldNormal = transform.inverted().transposed() * objectNormal

        return Tuple(worldNormal.xyzw.x, worldNormal.xyzw.y, worldNormal.xyzw.z, 0).normalized()
    }
}

#if TEST
import XCTest

extension SphereTests {

    func test_normal_xAxis() {
        let normal = Sphere()
            .normal(at: .point(1, 0, 0))

        XCTAssertEqual(normal, .vector(1, 0, 0))
    }

    func test_normal_yAxis() {
        let normal = Sphere()
            .normal(at: .point(0, 1, 0))

        XCTAssertEqual(normal, .vector(0, 1, 0))
    }

    func test_normal_zAxis() {
        let normal = Sphere()
            .normal(at: .point(0, 0, 1))

        XCTAssertEqual(normal, .vector(0, 0, 1))
    }

    func test_normal_point() {
        let value = sqrt(3) / 3
        let normal = Sphere()
            .normal(at: .point(value, value, value))

        XCTAssertEqual(normal, .vector(value, value, value))
    }

    func test_normal_isNormalized() {
        let value = sqrt(3) / 3
        let normal = Sphere()
            .normal(at: .point(value, value, value))

        XCTAssertEqual(normal, normal.normalized())
    }

    func test_normal_translatedSphere() {
        let normal = Sphere(transform: .translation(0, 1, 0))
            .normal(at: .point(0, 1.70711, -0.70711))

        XCTAssertEqual(normal, .vector(0, 0.70711, -0.70711))
    }

    func test_normal_transformedSphere() {
        let normal = Sphere(transform: .scaling(1, 0.5, 1) * .rotationZ(.pi / 5))
            .normal(at: .point(0, sqrt(2) / 2, -sqrt(2) / 2))

        XCTAssertEqual(normal, .vector(0, 0.97014, -0.24254))
    }
}
#endif

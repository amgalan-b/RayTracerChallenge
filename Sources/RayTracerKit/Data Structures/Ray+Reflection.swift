import Foundation

extension Ray {

    static func reflectionRay(position: Point, directionVector: Vector, normalVector: Vector) -> Ray {
        let reflectionVector = directionVector.reflected(on: normalVector)
        return Ray(origin: position, direction: reflectionVector)
    }
}

#if TEST
import XCTest

extension RayTests {

    func test_reflectionRay() {
        let ray = Ray.reflectionRay(
            position: Point(0, 0, 0),
            directionVector: Vector(1, 0, 0),
            normalVector: Vector(-1, 1, 0).normalized()
        )

        let expected = Ray(origin: Point(0, 0, 0), direction: Vector(0, 1, 0))
        XCTAssertEqual(ray, expected)
    }
}
#endif

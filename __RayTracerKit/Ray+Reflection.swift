import Foundation

extension Ray {

    static func reflectionRay(position: Tuple, directionVector: Tuple, normalVector: Tuple) -> Ray {
        let reflectionVector = directionVector.reflected(on: normalVector)
        return Ray(origin: position, direction: reflectionVector)
    }
}

#if TEST
import XCTest

extension RayTests {

    func test_reflectionRay() {
        let ray = Ray.reflectionRay(
            position: .point(0, 0, 0),
            directionVector: .vector(1, 0, 0),
            normalVector: .vector(-1, 1, 0).normalized()
        )

        let expected = Ray(origin: .point(0, 0, 0), direction: .vector(0, 1, 0))
        XCTAssertEqual(ray, expected)
    }
}
#endif

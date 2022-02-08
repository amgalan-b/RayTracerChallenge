import Foundation

extension Ray {

    static func refractionRay(
        refractiveIndices: RefractiveIndices,
        eyeVector: Vector,
        normalVector: Vector,
        position: Point
    ) -> Ray? {
        let n_ratio = refractiveIndices.n1 / refractiveIndices.n2
        let cos_i = eyeVector.dotProduct(with: normalVector)
        let sin2_t = n_ratio.pow(2) * (1 - cos_i.pow(2))
        let isTotalInternalReflection = sin2_t > 1

        guard !isTotalInternalReflection else {
            return nil
        }

        let cos_t = sqrt(1 - sin2_t)
        let direction = normalVector * (n_ratio * cos_i - cos_t) - eyeVector * n_ratio

        return Ray(origin: position, direction: direction)
    }
}

#if TEST
import XCTest

extension RayTests {

    func test_refractionRay() {
        let ray = Ray.refractionRay(
            refractiveIndices: [1, 1.5],
            eyeVector: Vector(0, 0, -1),
            normalVector: Vector(1, 1, 1).normalized(),
            position: Point(0, 0, 0)
        )
        let expected = Ray(origin: Point(0, 0, 0), direction: Vector(-0.70654, -0.70654, -0.03988))

        XCTAssertEqual(ray, expected)
    }

    func test_refractionRay_totalInternalReflection() {
        let ray = Ray.refractionRay(
            refractiveIndices: [1.5, 1],
            eyeVector: Vector(0, -1, 0),
            normalVector: Vector(0, -0.70711, -0.70711),
            position: Point(0, 0.70711, 0.70711)
        )

        XCTAssertNil(ray)
    }
}
#endif

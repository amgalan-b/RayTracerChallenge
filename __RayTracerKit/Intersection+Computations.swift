import Foundation

extension Intersection {

    func shade(for ray: Ray, light: Light) -> Color {
        let computations = _Computations(intersection: self, ray: ray)

        return computations.object.material.lighting(
            at: computations.position,
            light: light,
            eyeVector: computations.eyeVector,
            normal: computations.normalVector
        )
    }
}

private struct _Computations {

    let time: Double
    let object: Sphere
    let position: Tuple
    let eyeVector: Tuple
    let normalVector: Tuple

    let isInside: Bool

    init(intersection: Intersection, ray: Ray) {
        self.time = intersection.time
        self.object = intersection.object
        self.position = ray.position(at: time)
        self.eyeVector = -ray.direction

        let normalVector = object.normal(at: position)
        guard normalVector.dotProduct(with: eyeVector) >= 0 else {
            self.isInside = true
            self.normalVector = -normalVector
            return
        }

        self.isInside = false
        self.normalVector = normalVector
    }
}

#if TEST
import XCTest

extension IntersectionTests {

    func test_computations_intersectionOutside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 4, object: sphere)
        let computations = _Computations(intersection: intersection, ray: ray)

        XCTAssertFalse(computations.isInside)
    }

    func test_computations_intersectionInside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 1, object: sphere)
        let computations = _Computations(intersection: intersection, ray: ray)

        XCTAssert(computations.isInside)
        XCTAssertEqual(computations.position, .point(0, 0, 1))
        XCTAssertEqual(computations.eyeVector, .vector(0, 0, -1))
        XCTAssertEqual(computations.normalVector, .vector(0, 0, -1))
    }

    func test_shade_intersection() {
        let sphere = Sphere()
        sphere.material.color = .rgb(0.8, 1, 0.6)
        sphere.material.diffuse = 0.7
        sphere.material.specular = 0.2

        let light = Light.pointLight(at: .point(-10, 10, -10), intensity: .white)
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let shade = Intersection(time: 4, object: sphere)
            .shade(for: ray, light: light)

        XCTAssertEqual(shade, .rgb(0.38066, 0.47583, 0.2855))
    }

    func test_shade_intersectionInside() {
        let sphere = Sphere()
        let light = Light.pointLight(at: .point(0, 0.25, 0), intensity: .white)

        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let shade = Intersection(time: 0.5, object: sphere)
            .shade(for: ray, light: light)

        XCTAssertEqual(shade, .rgb(0.90498, 0.90498, 0.90498))
    }
}
#endif

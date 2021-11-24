import Foundation

extension Intersection {

    func prepareComputations(for ray: Ray) -> Computations {
        return Computations(intersection: self, ray: ray)
    }
}

extension Intersection {

    struct Computations {

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
}

#if TEST
import XCTest

extension IntersectionTests {

    func test_computations_intersectionOutside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let computations = Intersection(time: 4, object: sphere)
            .prepareComputations(for: ray)

        XCTAssertFalse(computations.isInside)
    }

    func test_computations_intersectionInside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let computations = Intersection(time: 1, object: sphere)
            .prepareComputations(for: ray)

        XCTAssert(computations.isInside)
        XCTAssertEqual(computations.position, .point(0, 0, 1))
        XCTAssertEqual(computations.eyeVector, .vector(0, 0, -1))
        XCTAssertEqual(computations.normalVector, .vector(0, 0, -1))
    }
}
#endif

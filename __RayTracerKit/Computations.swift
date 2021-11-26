import Foundation

struct Computations {

    let time: Double
    let object: Sphere
    let position: Tuple
    let eyeVector: Tuple
    let normalVector: Tuple

    let isInside: Bool
    let overPoint: Tuple

    init(intersection: Intersection, ray: Ray) {
        self.time = intersection.time
        self.object = intersection.object
        self.position = ray.position(at: time)
        self.eyeVector = -ray.direction

        let normalVector = object.normal(at: position)
        guard normalVector.dotProduct(with: eyeVector) >= 0 else {
            self.isInside = true
            self.normalVector = -normalVector
            self.overPoint = self.position + self.normalVector * .tolerance
            return
        }

        self.isInside = false
        self.normalVector = normalVector
        self.overPoint = self.position + self.normalVector * .tolerance
    }
}

#if TEST
import XCTest

final class ComputationTests: XCTestCase {

    func test_computations_intersectionOutside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 4, object: sphere)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssertFalse(computations.isInside)
    }

    func test_computations_intersectionInside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 1, object: sphere)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssert(computations.isInside)
        XCTAssertEqual(computations.position, .point(0, 0, 1))
        XCTAssertEqual(computations.eyeVector, .vector(0, 0, -1))
        XCTAssertEqual(computations.normalVector, .vector(0, 0, -1))
    }
}
#endif

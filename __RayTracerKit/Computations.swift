import Foundation

struct Computations {

    let time: Double
    let object: Shape
    let position: Tuple
    let eyeVector: Tuple
    let normalVector: Tuple

    /// Position slightly adjusted in normal direction to avoid self-intersection and shadow-acne.
    let normalAdjustedPosition: Tuple
    /// Position slightly adjusted in the opposite normal direction.
    let normalOppositeAdjustedPosition: Tuple
    let isInside: Bool

    init(intersection: Intersection, ray: Ray) {
        self.time = intersection.time
        self.object = intersection.object
        self.position = ray.position(at: time)
        self.eyeVector = -ray.direction

        let normalVector = object.normal(at: position, additionalData: intersection.additionalData)
        if normalVector.dotProduct(with: eyeVector) < 0 {
            self.isInside = true
            self.normalVector = -normalVector
        } else {
            self.isInside = false
            self.normalVector = normalVector
        }

        self.normalAdjustedPosition = self.position + self.normalVector * .tolerance
        self.normalOppositeAdjustedPosition = self.position - self.normalVector * .tolerance
    }
}

#if TEST
import XCTest

final class ComputationTests: XCTestCase {

    func test_isInside_intersectionOutside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 4, object: sphere)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssertFalse(computations.isInside)
    }

    func test_isInside_intersectionInside() {
        let sphere = Sphere()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let intersection = Intersection(time: 1, object: sphere)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssert(computations.isInside)
        XCTAssertEqual(computations.position, .point(0, 0, 1))
        XCTAssertEqual(computations.eyeVector, .vector(0, 0, -1))
        XCTAssertEqual(computations.normalVector, .vector(0, 0, -1))
    }

    func test_normalAdjustedPosition() {
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let shape = Sphere(transform: .translation(0, 0, 1))
        let intersection = Intersection(time: 5, object: shape)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssert(computations.normalAdjustedPosition.z < -.tolerance / 2)
        XCTAssert(computations.position.z > computations.normalAdjustedPosition.z)
    }

    func test_normalOppositeAdjustedPosition() {
        let shape = Sphere(material: .default(transparency: 1, refractiveIndex: 1.5), transform: .translation(0, 0, 1))
        let intersection = Intersection(time: 5, object: shape)
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, .tolerance / 2)
        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, computations.position.z)
    }
}
#endif

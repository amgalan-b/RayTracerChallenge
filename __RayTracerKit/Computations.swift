import Foundation

struct Computations {

    let time: Double
    let object: Shape
    let position: Tuple
    let eyeVector: Tuple
    let normalVector: Tuple
    let reflectionVector: Tuple

    /// Position slightly adjusted in normal direction to avoid self-intersection and shadow-acne.
    let normalAdjustedPosition: Tuple
    /// Position slightly adjusted in the opposite normal direction.
    let normalOppositeAdjustedPosition: Tuple
    let isInside: Bool

    /// Refractive index of the material that is the ray passing from.
    let n1: Double
    /// Refractive index of the material that is the ray passing through.
    let n2: Double

    init(intersection: Intersection, ray: Ray, refractiveIndices: (Double, Double) = (1, 1)) {
        self.time = intersection.time
        self.object = intersection.object
        self.position = ray.position(at: time)
        self.eyeVector = -ray.direction

        let normalVector = object.normal(at: position)
        if normalVector.dotProduct(with: eyeVector) < 0 {
            self.isInside = true
            self.normalVector = -normalVector
        } else {
            self.isInside = false
            self.normalVector = normalVector
        }

        self.normalAdjustedPosition = self.position + self.normalVector * .tolerance
        self.normalOppositeAdjustedPosition = self.position - self.normalVector * .tolerance
        self.reflectionVector = ray.direction.reflected(on: self.normalVector)
        self.n1 = refractiveIndices.0
        self.n2 = refractiveIndices.1
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

    func test_reflection() {
        let ray = Ray(origin: .point(0, 1, -1), direction: .vector(0, -sqrt(2) / 2, sqrt(2) / 2))
        let shape = Plane()
        let intersection = Intersection(time: sqrt(2), object: shape)
        let computations = Computations(intersection: intersection, ray: ray)

        XCTAssertEqual(computations.reflectionVector, .vector(0, sqrt(2) / 2, sqrt(2) / 2))
    }

    func test_underPoint() {
        let shape = Sphere(material: .default(transparency: 1, refractiveIndex: 1.5), transform: .translation(0, 0, 1))
        let intersection = Intersection(time: 5, object: shape)
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let computations = Computations(intersection: intersection, ray: ray, refractiveIndices: (1.5, 1.5))

        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, .tolerance / 2)
        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, computations.position.z)
    }
}
#endif

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

    func reflectanceSchlickApproximation() -> Double {
        let cos = eyeVector.dotProduct(with: normalVector)
        let r0 = ((n1 - n2) / (n1 + n2)).pow(2)

        guard n1 > n2 else {
            return r0 + (1 - r0) * (1 - cos).pow(5)
        }

        let n = n1 / n2
        let sin2_t = n.pow(2) * (1 - cos.pow(2))

        if sin2_t > 1 {
            return 1
        }

        let cos_t = sqrt(1 - sin2_t)

        return r0 + (1 - r0) * (1 - cos_t).pow(5)
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

    func test_normalOppositeAdjustedPosition() {
        let shape = Sphere(material: .default(transparency: 1, refractiveIndex: 1.5), transform: .translation(0, 0, 1))
        let intersection = Intersection(time: 5, object: shape)
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let computations = Computations(intersection: intersection, ray: ray, refractiveIndices: (1.5, 1.5))

        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, .tolerance / 2)
        XCTAssertGreaterThan(computations.normalOppositeAdjustedPosition.z, computations.position.z)
    }

    func test_reflectance() {
        let shape = Sphere(material: .default(transparency: 0.5, refractiveIndex: 1.5))
        let ray = Ray(origin: .point(0, 0, sqrt(2) / 2), direction: .vector(0, 1, 0))
        let intersections = [
            Intersection(time: -sqrt(2) / 2, object: shape),
            Intersection(time: sqrt(2) / 2, object: shape),
        ]

        let computations = Computations(
            intersection: intersections[1],
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: intersections[1])
        )

        XCTAssertEqual(computations.reflectanceSchlickApproximation(), 1)
    }

    func test_reflectance_perpendicularViewingAngle() {
        let shape = Sphere(material: .default(transparency: 0.5, refractiveIndex: 1.5))
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 1, 0))
        let intersections = [Intersection(time: -1, object: shape), Intersection(time: 1, object: shape)]
        let computations = Computations(
            intersection: intersections[1],
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: intersections[1])
        )

        XCTAssertEqual(computations.reflectanceSchlickApproximation(), 0.04, accuracy: .tolerance)
    }

    func test_reflectance_smallAngle() {
        let shape = Sphere(material: .default(transparency: 0.5, refractiveIndex: 1.5))
        let ray = Ray(origin: .point(0, 0.99, -2), direction: .vector(0, 0, 1))
        let intersections = [Intersection(time: 1.8589, object: shape)]
        let computations = Computations(
            intersection: intersections[0],
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: intersections[0])
        )

        XCTAssertEqual(computations.reflectanceSchlickApproximation(), 0.48873, accuracy: .tolerance)
    }
}
#endif

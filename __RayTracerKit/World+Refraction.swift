import Foundation

extension World {

    /// - Seealso: Snell's Law
    func _refractedColor(
        n1: Double,
        n2: Double,
        transparency: Double,
        eyeVector: Tuple,
        normalVector: Tuple,
        position: Tuple,
        recursionLimit: Int
    ) -> Color {
        guard recursionLimit > 0 else {
            return .black
        }

        guard transparency > 0 else {
            return .black
        }

        let nRatio = n1 / n2
        let cos_i = eyeVector.dotProduct(with: normalVector)
        let sin2_t = nRatio.pow(2) * (1 - cos_i.pow(2))
        let isTotalInternalReflection = sin2_t > 1

        guard !isTotalInternalReflection else {
            return .black
        }

        let cos_t = sqrt(1 - sin2_t)
        let direction = normalVector * (nRatio * cos_i - cos_t) - eyeVector * nRatio
        let refractedRay = Ray(origin: position, direction: direction)

        return color(for: refractedRay, recursionLimit: recursionLimit - 1) * transparency
    }
}

#if TEST
import XCTest

extension WorldTests {

    func test_refractedColor() {
        let world = World.makeDefault()
        let shape = world.objects[0]
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let intersections = [Intersection(time: 4, object: shape), Intersection(time: 6, object: shape)]
        let computations = Computations(
            intersection: intersections[0],
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: intersections[0])
        )

        let result = world._refractedColor(
            n1: computations.n1,
            n2: computations.n2,
            transparency: computations.object.material.transparency,
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector,
            position: computations.normalOppositeAdjustedPosition,
            recursionLimit: 5
        )

        XCTAssertEqual(result, .black)
    }

    func test_refractedColor_totalInternalReflection() {
        let world = World.makeDefault()
        let shape = world.objects[0]
        shape.material = .default(transparency: 1, refractiveIndex: 1.5)

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

        let result = world._refractedColor(
            n1: computations.n1,
            n2: computations.n2,
            transparency: computations.object.material.transparency,
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector,
            position: computations.normalOppositeAdjustedPosition,
            recursionLimit: 5
        )

        XCTAssertEqual(result, .black)
    }

    func test_refractedColor_refractedRay() {
        let world = World.makeDefault()
        let s1 = world.objects[0]
        s1.material = .default(ambient: 1, pattern: .test())

        let s2 = world.objects[1]
        s2.material = .default(transparency: 1, refractiveIndex: 1.5)

        let ray = Ray(origin: .point(0, 0, 0.1), direction: .vector(0, 1, 0))
        let intersections = [
            Intersection(time: -0.9899, object: s1),
            Intersection(time: -0.4899, object: s2),
            Intersection(time: 0.4899, object: s2),
            Intersection(time: 0.9899, object: s1),
        ]

        let computations = Computations(
            intersection: intersections[2],
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: intersections[2])
        )

        let result = world._refractedColor(
            n1: computations.n1,
            n2: computations.n2,
            transparency: computations.object.material.transparency,
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector,
            position: computations.normalOppositeAdjustedPosition,
            recursionLimit: 5
        )

        XCTAssertEqual(result, .rgb(0, 0.99887, 0.04722))
    }

    func test_color_refraction() {
        let world = World.makeDefault()
        let floor = Plane(
            material: .default(transparency: 0.5, refractiveIndex: 1.5),
            transform: .translation(0, -1, 0)
        )
        let ball = Sphere(
            material: .default(color: .rgb(1, 0, 0), ambient: 0.5),
            transform: .translation(0, -3.5, -0.5)
        )

        world.objects.append(floor)
        world.objects.append(ball)

        let ray = Ray(origin: .point(0, 0, -3), direction: .vector(0, -sqrt(2) / 2, sqrt(2) / 2))
        let result = world.color(for: ray)

        XCTAssertEqual(result, .rgb(0.93642, 0.68642, 0.68642))
    }
}
#endif

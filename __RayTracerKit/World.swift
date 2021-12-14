import Foundation

public final class World {

    var objects: [Shape]
    var light: Light?

    public init(objects: [Shape] = [], light: Light? = nil) {
        self.objects = objects
        self.light = light
    }

    func color(for ray: Ray, recursionLimit: Int = Constants.reflectionRecursionDepth) -> Color {
        guard let light = light else {
            return .black
        }

        let intersections = _intersect(with: ray)
        guard let hit = intersections.hit() else {
            return .black
        }

        let computations = Computations(
            intersection: hit,
            ray: ray,
            refractiveIndices: intersections.refractiveIndices(hit: hit)
        )

        let surfaceColor = computations.object.material.lighting(
            at: computations.normalAdjustedPosition,
            light: light,
            eyeVector: computations.eyeVector,
            normal: computations.normalVector,
            objectTransform: computations.object.transform,
            shadowIntensity: light.shadowIntensity(
                at: computations.normalAdjustedPosition,
                isShadowed: _isShadowed(at:lightPosition:)
            )
        )

        let reflectedColor = _reflectedColor(
            on: computations.object.material,
            at: computations.normalAdjustedPosition,
            reflectionVector: computations.reflectionVector,
            recursionLimit: recursionLimit
        )

        let refractedColor = _refractedColor(
            n1: computations.n1,
            n2: computations.n2,
            transparency: computations.object.material.transparency,
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector,
            position: computations.normalOppositeAdjustedPosition,
            recursionLimit: recursionLimit
        )

        guard computations.object.material.reflective > 0, computations.object.material.transparency > 0 else {
            return surfaceColor + reflectedColor + refractedColor
        }

        let reflectance = computations.reflectanceSchlickApproximation()
        return surfaceColor + reflectedColor * reflectance + refractedColor * (1 - reflectance)
    }

    fileprivate func _intersect(with ray: Ray) -> [Intersection] {
        return objects.flatMap { $0.intersect(with: ray) }
            .sorted(by: \.time)
    }

    fileprivate func _isShadowed(at point: Tuple, lightPosition: Tuple) -> Bool {
        let lightVector = lightPosition - point
        let distance = lightVector.magnitude
        let direction = lightVector.normalized()
        let ray = Ray(origin: point, direction: direction)
        let intersections = _intersect(with: ray)

        guard let hit = intersections.hit() else {
            return false
        }

        return hit.time < distance
    }

    fileprivate func _reflectedColor(
        on material: Material,
        at position: Tuple,
        reflectionVector: Tuple,
        recursionLimit: Int
    ) -> Color {
        guard recursionLimit > 0 else {
            return .black
        }

        guard material.reflective > 0 else {
            return .black
        }

        let reflectedRay = Ray(origin: position, direction: reflectionVector)
        let color = color(for: reflectedRay, recursionLimit: recursionLimit - 1)

        return color * material.reflective
    }

    /// - Seealso: Snell's Law
    fileprivate func _refractedColor(
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

extension World {

    static func makeDefault() -> World {
        let s1 = Sphere(material: .default(color: .rgb(0.8, 1, 0.6), diffuse: 0.7, specular: 0.2))
        let s2 = Sphere(transform: .scaling(0.5, 0.5, 0.5))

        return World(objects: [s1, s2], light: .pointLight(at: .point(-10, 10, -10), intensity: .white))
    }
}

#if TEST
import XCTest

final class WorldTests: XCTestCase {

    func test_intersect() {
        let world = World.makeDefault()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let times = world._intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [4, 4.5, 5.5, 6])
    }

    func test_color_rayMiss() {
        let world = World.makeDefault()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 1, 0))

        XCTAssertEqual(world.color(for: ray), .black)
    }

    func test_color_rayHit() {
        let world = World.makeDefault()
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))

        XCTAssertEqual(world.color(for: ray), .rgb(0.38066, 0.47583, 0.2855))
    }

    func test_isShadowed() {
        let world = World.makeDefault()
        let lightPosition = Tuple.point(-10, -10, -10)

        XCTAssertFalse(world._isShadowed(at: .point(-10, -10, 10), lightPosition: lightPosition))
        XCTAssert(world._isShadowed(at: .point(10, 10, 10), lightPosition: lightPosition))
        XCTAssertFalse(world._isShadowed(at: .point(-20, -20, -20), lightPosition: lightPosition))
        XCTAssertFalse(world._isShadowed(at: .point(-5, -5, -5), lightPosition: lightPosition))
    }

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

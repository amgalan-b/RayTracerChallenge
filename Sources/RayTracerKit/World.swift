import Foundation

public final class World {

    private var _objects: [Shape]
    private var _light: Light?

    init(objects: [Shape] = [], light: Light? = nil) {
        _objects = objects
        _light = light
    }

    var light: Light? {
        get { _light }
        set { _light = newValue }
    }

    public func addObject(_ shape: Shape) {
        _objects.append(shape)
    }

    func color(for ray: Ray, recursionDepth: Int = 0) -> Color {
        guard let light = _light else {
            return .black
        }

        let intersections = _intersect(with: ray)
        guard let hit = intersections.hit() else {
            return .black
        }

        let computations = Computations(intersection: hit, ray: ray)
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

        guard Constants.maxRecursionDepth > recursionDepth else {
            return surfaceColor
        }

        let refractiveIndices = intersections.refractiveIndices(hit: hit)
        let reflectedColor = _reflectedColor(ray: ray, computations: computations, recursionDepth: recursionDepth)
        let refractedColor = _refractedColor(
            refractiveIndices: refractiveIndices,
            computations: computations,
            recursionDepth: recursionDepth
        )

        guard computations.object.material.reflective > 0, computations.object.material.transparency > 0 else {
            return surfaceColor + reflectedColor + refractedColor
        }

        let reflectance = refractiveIndices.reflectanceSchlickApproximation(
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector
        )

        return surfaceColor + reflectedColor * reflectance + refractedColor * (1 - reflectance)
    }

    fileprivate func _intersect(with ray: Ray) -> [Intersection] {
        return _objects.flatMap { $0.intersect(with: ray) }
            .sorted(by: \.time)
    }

    fileprivate func _isShadowed(at point: Point, lightPosition: Point) -> Bool {
        let lightVector = lightPosition - point
        let distance = lightVector.magnitude
        let direction = lightVector.normalized()
        let ray = Ray(origin: point, direction: direction)
        let intersections = _intersect(with: ray)
            .filter { $0.object.isShadowCasting }

        guard let hit = intersections.hit() else {
            return false
        }

        return hit.time < distance
    }

    private func _reflectedColor(ray: Ray, computations: Computations, recursionDepth: Int) -> Color {
        guard computations.object.material.reflective > 0 else {
            return .black
        }

        let reflectedRay = Ray.reflectionRay(
            position: computations.normalAdjustedPosition,
            directionVector: ray.direction,
            normalVector: computations.normalVector
        )

        return color(for: reflectedRay, recursionDepth: recursionDepth + 1) * computations.object.material.reflective
    }

    private func _refractedColor(
        refractiveIndices: RefractiveIndices,
        computations: Computations,
        recursionDepth: Int
    ) -> Color {
        guard computations.object.material.transparency > 0 else {
            return .black
        }

        guard let refractedRay = Ray.refractionRay(
            refractiveIndices: refractiveIndices,
            eyeVector: computations.eyeVector,
            normalVector: computations.normalVector,
            position: computations.normalOppositeAdjustedPosition
        ) else {
            return .black
        }

        return color(for: refractedRay, recursionDepth: recursionDepth + 1) * computations.object.material.transparency
    }
}

extension World {

    static func makeDefault() -> World {
        let s1 = Sphere(material: .default(color: .rgb(0.8, 1, 0.6), diffuse: 0.7, specular: 0.2))
        let s2 = Sphere(transform: .scaling(0.5, 0.5, 0.5))

        return World(objects: [s1, s2], light: .pointLight(at: Point(-10, 10, -10), intensity: .white))
    }
}

#if TEST
import XCTest

final class WorldTests: XCTestCase {

    func test_intersect() {
        let world = World.makeDefault()
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let times = world._intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [4, 4.5, 5.5, 6])
    }

    func test_color_rayMiss() {
        let world = World.makeDefault()
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 1, 0))

        XCTAssertEqual(world.color(for: ray), .black)
    }

    func test_color_rayHit() {
        let world = World.makeDefault()
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))

        XCTAssertEqual(world.color(for: ray), .rgb(0.38066, 0.47583, 0.2855))
    }

    func test_isShadowed() {
        let world = World.makeDefault()
        let lightPosition = Point(-10, -10, -10)

        XCTAssertFalse(world._isShadowed(at: Point(-10, -10, 10), lightPosition: lightPosition))
        XCTAssert(world._isShadowed(at: Point(10, 10, 10), lightPosition: lightPosition))
        XCTAssertFalse(world._isShadowed(at: Point(-20, -20, -20), lightPosition: lightPosition))
        XCTAssertFalse(world._isShadowed(at: Point(-5, -5, -5), lightPosition: lightPosition))
    }
}
#endif

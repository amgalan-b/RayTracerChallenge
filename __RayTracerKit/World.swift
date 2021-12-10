import Foundation

public final class World {

    var objects: [Shape]
    var light: Light?

    public init(objects: [Shape] = [], light: Light? = nil) {
        self.objects = objects
        self.light = light
    }

    func color(for ray: Ray) -> Color {
        guard let light = light else {
            return .black
        }

        let intersections = _intersect(with: ray)
        guard let hit = intersections.hit() else {
            return .black
        }

        let computations = Computations(intersection: hit, ray: ray)

        return computations.object.material.lighting(
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
}

extension World {

    static func makeDefault() -> World {
        let s1 = Sphere()
        s1.material.color = .rgb(0.8, 1, 0.6)
        s1.material.diffuse = 0.7
        s1.material.specular = 0.2

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
}
#endif

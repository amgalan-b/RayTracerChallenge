import Foundation

final class World {

    var objects: [Sphere]
    var light: Light?

    init(objects: [Sphere] = [], light: Light? = nil) {
        self.objects = objects
        self.light = light
    }

    func color(for ray: Ray) -> Color {
        let intersections = intersect(with: ray)
        guard let hit = intersections.hit() else {
            return .black
        }

        return hit.shade(for: ray, light: light!)
    }

    func intersect(with ray: Ray) -> [Intersection] {
        return objects.flatMap { $0.intersect(with: ray) }
            .sorted(by: \.time)
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
        let times = world.intersect(with: ray)
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
}
#endif

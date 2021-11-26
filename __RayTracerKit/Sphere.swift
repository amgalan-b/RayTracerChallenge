import Foundation

public final class Sphere {

    public var material: Material
    public var transform: Matrix

    public init(material: Material = .default, transform: Matrix = .identity) {
        self.material = material
        self.transform = transform
    }

    func intersect(with ray: Ray) -> [Intersection] {
        let transformedRay = ray.transformed(with: transform.inverted())
        let distance = transformedRay.origin - .point(0, 0, 0)
        let a = transformedRay.direction.dotProduct(with: transformedRay.direction)
        let b = 2 * transformedRay.direction.dotProduct(with: distance)
        let c = distance.dotProduct(with: distance) - 1

        let discriminant = b * b - 4 * a * c
        guard discriminant >= 0 else {
            return []
        }

        let t1 = (-b - discriminant.squareRoot()) / (2 * a)
        let t2 = (-b + discriminant.squareRoot()) / (2 * a)

        return [Intersection(time: t1, object: self), Intersection(time: t2, object: self)]
    }
}

extension Sphere: Equatable {

    public static func == (lhs: Sphere, rhs: Sphere) -> Bool {
        return lhs === rhs
    }
}

#if TEST
import XCTest

final class SphereTests: XCTestCase {

    func test_intersect() {
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [4.0, 6.0])
    }

    func test_intersect_tangent() {
        let ray = Ray(origin: .point(0, 1, -5), direction: .vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [5.0, 5.0])
    }

    func test_intersect_miss() {
        let ray = Ray(origin: .point(0, 2, -5), direction: .vector(0, 0, 1))
        let sphere = Sphere()

        XCTAssertEqual(sphere.intersect(with: ray), [])
    }

    func test_intersect_rayOriginWithin() {
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [-1.0, 1.0])
    }

    func test_intersect_shapeBehindRay() {
        let ray = Ray(origin: .point(0, 0, 5), direction: .vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [-6.0, -4.0])
    }

    func test_intersect_objectIsSphere() {
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.object }

        XCTAssertEqual(result, [sphere, sphere])
    }

    func test_intersect_scaledSphere() {
        let sphere = Sphere(transform: .scaling(2, 2, 2))
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))
        let times = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(times, [3, 7])
    }

    func test_intersect_translatedSphere() {
        let sphere = Sphere(transform: .translation(5, 0, 0))
        let ray = Ray(origin: .point(0, 0, -5), direction: .vector(0, 0, 1))

        XCTAssertEqual(sphere.intersect(with: ray), [])
    }
}
#endif

import Foundation

public final class Sphere: Shape {

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        let distance = ray.origin - Point(0, 0, 0)
        let a = ray.direction.dotProduct(with: ray.direction)
        let b = 2 * ray.direction.dotProduct(with: distance)
        let c = distance.dotProduct(with: distance) - 1

        let discriminant = b * b - 4 * a * c
        guard discriminant >= 0 else {
            return []
        }

        let t1 = (-b - discriminant.squareRoot()) / (2 * a)
        let t2 = (-b + discriminant.squareRoot()) / (2 * a)

        return [Intersection(time: t1, object: self), Intersection(time: t2, object: self)]
    }

    override func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        return point - Point(0, 0, 0)
    }

    override func boundingBoxLocal() -> BoundingBox {
        return BoundingBox(minimum: Point(-1, -1, -1), maximum: Point(1, 1, 1))
    }
}

#if TEST
import XCTest

final class SphereTests: XCTestCase {

    func test_intersect() {
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [4.0, 6.0])
    }

    func test_intersect_tangent() {
        let ray = Ray(origin: Point(0, 1, -5), direction: Vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [5.0, 5.0])
    }

    func test_intersect_miss() {
        let ray = Ray(origin: Point(0, 2, -5), direction: Vector(0, 0, 1))
        let sphere = Sphere()

        XCTAssertEqual(sphere.intersect(with: ray), [])
    }

    func test_intersect_rayOriginWithin() {
        let ray = Ray(origin: Point(0, 0, 0), direction: Vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [-1.0, 1.0])
    }

    func test_intersect_shapeBehindRay() {
        let ray = Ray(origin: Point(0, 0, 5), direction: Vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.time }

        XCTAssertEqual(result, [-6.0, -4.0])
    }

    func test_intersect_objectIsSphere() {
        let ray = Ray(origin: Point(0, 0, -5), direction: Vector(0, 0, 1))
        let sphere = Sphere()
        let result = sphere.intersect(with: ray)
            .map { $0.object }

        XCTAssertEqual(result, [sphere, sphere])
    }

    func test_normal_xAxis() {
        let normal = Sphere()
            .normal(at: Point(1, 0, 0))

        XCTAssertEqual(normal, Vector(1, 0, 0))
    }

    func test_normal_yAxis() {
        let normal = Sphere()
            .normal(at: Point(0, 1, 0))

        XCTAssertEqual(normal, Vector(0, 1, 0))
    }

    func test_normal_zAxis() {
        let normal = Sphere()
            .normal(at: Point(0, 0, 1))

        XCTAssertEqual(normal, Vector(0, 0, 1))
    }

    func test_normal_point() {
        let value = sqrt(3) / 3
        let normal = Sphere()
            .normal(at: Point(value, value, value))

        XCTAssertEqual(normal, Vector(value, value, value))
    }

    func test_normal_isNormalized() {
        let value = sqrt(3) / 3
        let normal = Sphere()
            .normal(at: Point(value, value, value))

        XCTAssertEqual(normal, normal.normalized())
    }

    func test_boundingBox() {
        let sphere = Sphere()
        let box = sphere.boundingBoxLocal()

        XCTAssertEqual(box.minimum, Point(-1, -1, -1))
        XCTAssertEqual(box.maximum, Point(1, 1, 1))
    }
}
#endif

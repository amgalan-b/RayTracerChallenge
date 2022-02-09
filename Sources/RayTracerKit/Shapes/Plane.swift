import Foundation

final class Plane: Shape {

    override func normalLocal(at point: Point, additionalData: ShapeIntersectionData? = nil) -> Vector {
        return Vector(0, 1, 0)
    }

    override func intersectLocal(with ray: Ray) -> [Intersection] {
        guard ray.direction.y.absoluteValue >= .tolerance else {
            return []
        }

        let time = -ray.origin.y / ray.direction.y
        return [Intersection(time: time, object: self)]
    }
}

#if TEST
import XCTest

final class PlaneTests: XCTestCase {

    func test_normal_isConstantEverywhere() {
        let plane = Plane()

        let n1 = plane.normal(at: Point(0, 0, 0))
        let n2 = plane.normal(at: Point(10, 0, -10))
        let n3 = plane.normal(at: Point(-5, 0, 150))

        XCTAssertEqual(n1, Vector(0, 1, 0))
        XCTAssertEqual(n2, Vector(0, 1, 0))
        XCTAssertEqual(n3, Vector(0, 1, 0))
    }

    func test_intersection_rayParallelToPlane() {
        let plane = Plane()
        let ray = Ray(origin: Point(0, 10, 0), direction: Vector(0, 0, 1))

        XCTAssertEqual(plane.intersect(with: ray), [])
    }

    func test_intersection_rayCoplanar() {
        let plane = Plane()
        let ray = Ray(origin: Point(0, 0, 0), direction: Vector(0, 0, 1))

        XCTAssertEqual(plane.intersect(with: ray), [])
    }

    func test_intersection_rayAbove() {
        let plane = Plane()
        let ray = Ray(origin: Point(0, 1, 0), direction: Vector(0, -1, 0))
        let expected = [Intersection(time: 1, object: plane)]

        XCTAssertEqual(plane.intersect(with: ray), expected)
    }

    func test_intersection_rayBelow() {
        let plane = Plane()
        let ray = Ray(origin: Point(0, -1, 0), direction: Vector(0, 1, 0))
        let expected = [Intersection(time: 1, object: plane)]

        XCTAssertEqual(plane.intersect(with: ray), expected)
    }
}
#endif

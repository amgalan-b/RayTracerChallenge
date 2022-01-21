import Foundation

public final class Plane: Shape {

    override func normalLocal(at point: Tuple, additionalData: ShapeIntersectionData? = nil) -> Tuple {
        return .vector(0, 1, 0)
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

        let n1 = plane.normal(at: .point(0, 0, 0))
        let n2 = plane.normal(at: .point(10, 0, -10))
        let n3 = plane.normal(at: .point(-5, 0, 150))

        XCTAssertEqual(n1, .vector(0, 1, 0))
        XCTAssertEqual(n2, .vector(0, 1, 0))
        XCTAssertEqual(n3, .vector(0, 1, 0))
    }

    func test_intersection_rayParallelToPlane() {
        let plane = Plane()
        let ray = Ray(origin: .point(0, 10, 0), direction: .vector(0, 0, 1))

        XCTAssertEqual(plane.intersect(with: ray), [])
    }

    func test_intersection_rayCoplanar() {
        let plane = Plane()
        let ray = Ray(origin: .point(0, 0, 0), direction: .vector(0, 0, 1))

        XCTAssertEqual(plane.intersect(with: ray), [])
    }

    func test_intersection_rayAbove() {
        let plane = Plane()
        let ray = Ray(origin: .point(0, 1, 0), direction: .vector(0, -1, 0))
        let expected = [Intersection(time: 1, object: plane)]

        XCTAssertEqual(plane.intersect(with: ray), expected)
    }

    func test_intersection_rayBelow() {
        let plane = Plane()
        let ray = Ray(origin: .point(0, -1, 0), direction: .vector(0, 1, 0))
        let expected = [Intersection(time: 1, object: plane)]

        XCTAssertEqual(plane.intersect(with: ray), expected)
    }
}
#endif
